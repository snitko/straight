require 'spec_helper'

RSpec.describe Straight::Gateway do

  before(:each) do
    @mock_adapter                  = double("mock blockchain adapter")
    @gateway                       = Straight::Gateway.new
    @gateway.pubkey                = "pubkey"
    @gateway.order_class           = "Straight::Order"
    @gateway.blockchain_adapters   = [@mock_adapter]
    @gateway.status_check_schedule = Straight::Gateway::DEFAULT_STATUS_CHECK_SCHEDULE
    @gateway.order_callbacks       = []
  end

  it "passes methods on to the available adapter" do
    @gateway.instance_variable_set('@blockchain_adapters', [@mock_adapter])
    expect(@mock_adapter).to receive(:fetch_transaction).once 
    @gateway.fetch_transaction("xxx")
  end

  it "uses the next availabale adapter when something goes wrong with the current one" do
    another_mock_adapter = double("another_mock blockchain adapter")
    @gateway.instance_variable_set('@blockchain_adapters', [@mock_adapter, another_mock_adapter])
    allow(@mock_adapter).to receive(:fetch_transaction).once.and_raise(Exception) 
    expect(another_mock_adapter).to receive(:fetch_transaction).once 
    @gateway.fetch_transaction("xxx")
  end

  it "creates new orders and addresses for them" do
    @gateway.pubkey   = MoneyTree::Master.new.to_serialized_address 
    expected_address  = MoneyTree::Node.from_serialized_address(@gateway.pubkey).node_for_path("1").to_address
    expect(@gateway.order_for_keychain_id(amount: 1, keychain_id: 1).address).to eq(expected_address)
  end

  it "calls all the order callbacks" do
    callback1                = double('callback1')
    callback2                = double('callback1')
    @gateway.pubkey          = MoneyTree::Master.new.to_serialized_address
    @gateway.order_callbacks = [callback1, callback2]

    order = @gateway.order_for_keychain_id(amount: 1, keychain_id: 1)
    expect(callback1).to receive(:call).with(order)
    expect(callback2).to receive(:call).with(order)
    @gateway.order_status_changed(order)
  end

  describe "exchange rate calculation" do

    it "sets order amount in satoshis calculated from another currency" do
      adapter = Straight::ExchangeRate::BitpayAdapter.new
      allow(adapter).to receive(:rate_for).and_return(450.5412)
      @gateway.exchange_rate_adapters = [adapter]
      expect(@gateway.amount_from_exchange_rate(2252.706, currency: 'USD')).to eq(500000000)
    end

    it "tries various exchange adapters until one of them actually returns an exchange rate" do
      adapter1 = Straight::ExchangeRate::BitpayAdapter.new
      adapter2 = Straight::ExchangeRate::BitpayAdapter.new
      allow(adapter1).to receive(:rate_for).and_return( -> { raise "connection problem" })
      allow(adapter2).to receive(:rate_for).and_return(450.5412)
      @gateway.exchange_rate_adapters = [adapter1, adapter2]
      expect(@gateway.amount_from_exchange_rate(2252.706, currency: 'USD')).to eq(500000000)
    end

    it "converts btc denomination into satoshi if provided with :btc_denomination" do
      expect(@gateway.amount_from_exchange_rate(5, currency: 'BTC', btc_denomination: :btc)).to eq(500000000)
    end

  end

end
