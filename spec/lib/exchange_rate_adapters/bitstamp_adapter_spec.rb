require 'spec_helper'

RSpec.describe Straight::ExchangeRate::BitstampAdapter do

  before(:each) do
    @exchange_adapter = Straight::ExchangeRate::BitstampAdapter.new
  end

  it "finds the rate for currency code" do
    expect(@exchange_adapter.rate_for('USD')).to be_kind_of(Float)
    expect( -> { @exchange_adapter.rate_for('FEDcoin') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
  end

  it "raises exception if rate is nil" do
    json_response_1 = '{}'
    json_response_2 = '{"high": "232.89", "list": "224.13", "timestamp": "1423457015", "bid": "224.00", "vwap": "224.57", "volume": "14810.41127494", "low": "217.28", "ask": "224.13"}'
    json_response_3 = '{"high": "232.89", "last": "null", "timestamp": "1423457015", "bid": "224.00", "vwap": "224.57", "volume": "14810.41127494", "low": "217.28", "ask": "224.13"}'
    uri_mock = double('uri mock')
    allow(uri_mock).to receive(:read).with(read_timeout: 4).and_return(json_response_1, json_response_2, json_response_3)
    allow(URI).to      receive(:parse).and_return(uri_mock)
    3.times do
      @exchange_adapter.fetch_rates!
      expect( -> { @exchange_adapter.rate_for('USD') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
    end
  end

end
