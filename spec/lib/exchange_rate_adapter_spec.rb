require 'spec_helper'

RSpec.describe Straight::ExchangeRate::Adapter do

  class Straight::ExchangeRate::Adapter
    FETCH_URL = ''
  end

  before(:each) do
    @exchange_adapter = Straight::ExchangeRate::Adapter.new
  end

  describe "converting currencies" do

    before(:each) do
      allow(@exchange_adapter).to receive(:fetch_rates!)
      allow(@exchange_adapter).to receive(:rate_for).with('USD').and_return(450.5412)
    end

    it "converts amount from currency into BTC" do
      expect(@exchange_adapter.convert_from_currency(2252.706, currency: 'USD')).to eq(500000000)
    end

    it "converts from btc into currency" do
      expect(@exchange_adapter.convert_to_currency(500000000, currency: 'USD')).to eq(2252.706)
    end

    it "shows btc amounts in various denominations" do
      expect(@exchange_adapter.convert_from_currency(2252.706, currency: 'USD', btc_denomination: :btc)).to eq(5)
      expect(@exchange_adapter.convert_to_currency(5, currency: 'USD', btc_denomination: :btc)).to eq(2252.706)
    end

    it "accepts string as amount and converts it properly" do
      expect(@exchange_adapter.convert_from_currency('2252.706', currency: 'USD', btc_denomination: :btc)).to eq(5)
      expect(@exchange_adapter.convert_to_currency('5', currency: 'USD', btc_denomination: :btc)).to eq(2252.706)
    end

  end

  it "when checking for rates, only calls fetch_rates! if they were checked long time ago or never" do
    uri_mock = double('uri mock')
    expect(URI).to      receive(:parse).and_return(uri_mock).twice
    expect(uri_mock).to receive(:read).and_return('{ "USD": 534.4343 }').twice
    @exchange_adapter.rate_for('USD')
    @exchange_adapter.rate_for('USD') # not calling fetch_rates! because we've just checked
    @exchange_adapter.instance_variable_set(:@rates_updated_at, Time.now-1900)
    @exchange_adapter.rate_for('USD')
  end

  it "raises exception if rate is nil" do
    rate = nil
    expect( -> { @exchange_adapter.rate_to_f(rate) }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
  end

end
