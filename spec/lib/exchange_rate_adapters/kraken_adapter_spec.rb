require 'spec_helper'

RSpec.describe Straight::ExchangeRate::KrakenAdapter do

  before(:each) do
    @exchange_adapter = Straight::ExchangeRate::KrakenAdapter.new
  end

  it "finds the rate for currency code" do
    expect(@exchange_adapter.rate_for('USD')).to be_kind_of(Float)
    expect( -> { @exchange_adapter.rate_for('FEDcoin') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
  end

  it "raises exception if rate is nil" do
    json_response_1 = '{"error":[],"result":{}}'
    json_response_2 = '{"error":[],"result":{"XXBTZUSD":{"a":["244.95495","1"],"b":["227.88761","1"],"abc":["228.20494","0.10000000"],"v":["5.18645337","24.04033530"],"p":["234.92296","234.41356"],"t":[45,74],"l":["228.20494","228.20494"],"h":["239.36069","239.36069"],"o":"231.82976"}}}'
    json_response_3 = '{"error":[],"result":{"XXBTZUSD":{"a":["244.95495","1"],"b":["227.88761","1"],"c":[null,"0.10000000"],"v":["5.18645337","24.04033530"],"p":["234.92296","234.41356"],"t":[45,74],"l":["228.20494","228.20494"],"h":["239.36069","239.36069"],"o":"231.82976"}}}'
    uri_mock = double('uri mock')
    allow(uri_mock).to receive(:read).with(read_timeout: 4).and_return(json_response_1, json_response_2, json_response_3)
    allow(URI).to      receive(:parse).and_return(uri_mock)
    3.times do
      expect( -> { @exchange_adapter.rate_for('USD') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
    end
  end

end