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

  it "shares exchange rate adapter(s) instances between all/multiple gateway instances" do
    gateway_2 = Straight::Gateway.new.tap do |g|
      g.pubkey                = "pubkey"
      g.order_class           = "Straight::Order"
      g.blockchain_adapters   = [@mock_adapter]
      g.status_check_schedule = Straight::Gateway::DEFAULT_STATUS_CHECK_SCHEDULE
      g.order_callbacks       = []
    end
    # Checking if exchange rate adapters are the same objects for both gateways
    @gateway.instance_variable_get(:@exchange_rate_adapters).each_with_index do |adapter, i|
      expect(gateway_2.instance_variable_get(:@exchange_rate_adapters)[i]).to be adapter
    end
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
    @gateway.pubkey   = 'xpub661MyMwAqRbcFhUeRviyfia1NdfX4BAv5zCsZ6HqsprRjdBDK8vwh3kfcnTvqNbmi5S1yZ5qL9ugZTyVqtyTZxccKZzMVMCQMhARycvBZvx' 
    expected_address  = '1NEvrcxS3REbJgup8rMA4QvMFFSdWTLvM'
    expect(@gateway.new_order(amount: 1, keychain_id: 1).address).to eq(expected_address)
  end

  it "calls all the order callbacks" do
    callback1                = double('callback1')
    callback2                = double('callback1')
    @gateway.pubkey          = MoneyTree::Master.new.to_bip32
    @gateway.order_callbacks = [callback1, callback2]

    order = @gateway.new_order(amount: 1, keychain_id: 1)
    expect(callback1).to receive(:call).with(order)
    expect(callback2).to receive(:call).with(order)
    @gateway.order_status_changed(order)
  end

  describe "exchange rate calculation" do

    it "sets order amount in satoshis calculated from another currency" do
      adapter = Straight::ExchangeRate::BitpayAdapter.instance
      allow(adapter).to receive(:rate_for).and_return(450.5412)
      @gateway.exchange_rate_adapters = [adapter]
      expect(@gateway.amount_from_exchange_rate(2252.706, currency: 'USD')).to eq(500000000)
    end

    it "tries various exchange adapters until one of them actually returns an exchange rate" do
      adapter1 = Straight::ExchangeRate::BitpayAdapter.instance
      adapter2 = Straight::ExchangeRate::BitpayAdapter.instance
      allow(adapter1).to receive(:rate_for).and_return( -> { raise "connection problem" })
      allow(adapter2).to receive(:rate_for).and_return(450.5412)
      @gateway.exchange_rate_adapters = [adapter1, adapter2]
      expect(@gateway.amount_from_exchange_rate(2252.706, currency: 'USD')).to eq(500000000)
    end

    it "converts btc denomination into satoshi if provided with :btc_denomination" do
      expect(@gateway.amount_from_exchange_rate(5, currency: 'BTC', btc_denomination: :btc)).to eq(500000000)
    end

    it "accepts string as amount and converts it properly" do
      expect(@gateway.amount_from_exchange_rate('0.5', currency: 'BTC', btc_denomination: :btc)).to eq(50000000)
    end

    it "simply fetches current exchange rate for 1 BTC" do
      expect(@gateway.current_exchange_rate('USD')).not_to be_nil
    end

  end

end
