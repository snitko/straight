require 'spec_helper'

RSpec.describe Straight::ExchangeRate::CoinbaseAdapter do

  before(:each) do
    @exchange_adapter = Straight::ExchangeRate::CoinbaseAdapter.new
  end

  it "finds the rate for currency code" do
    expect(@exchange_adapter.rate_for('USD')).to be_kind_of(Float)
    expect( -> { @exchange_adapter.rate_for('FEDcoin') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
  end

  it "raises exception if rate is nil" do
    json_response_1 = '{}'
    json_response_2 = '{"btc_to_urd":"224.41","usd_to_xpf":"105.461721","bsd_to_btc":"0.004456"}'
    json_response_3 = '{"btc_to_usd":null,"usd_to_xpf":"105.461721","bsd_to_btc":"0.004456"}'
    uri_mock = double('uri mock')
    allow(uri_mock).to receive(:read).with(read_timeout: 4).and_return(json_response_1, json_response_2, json_response_3)
    allow(URI).to      receive(:parse).and_return(uri_mock)
    3.times do
      @exchange_adapter.fetch_rates!
      expect( -> { @exchange_adapter.rate_for('USD') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
    end
  end

end
