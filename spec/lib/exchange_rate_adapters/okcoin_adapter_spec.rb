require 'spec_helper'

RSpec.describe Straight::ExchangeRate::OkcoinAdapter do

  before(:each) do
    @exchange_adapter = Straight::ExchangeRate::OkcoinAdapter.new
  end

  it "finds the rate for currency code" do
    expect(@exchange_adapter.rate_for('USD')).to be_kind_of(Float)
    expect( -> { @exchange_adapter.rate_for('FEDcoin') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
  end

  it "rases exception if rate is nil" do
    json_response_1 = '{"date":"1422679981","ticker":{}}'
    json_response_2 = '{{"date":"1422679981","ticker":{"buy":"227.27","high":"243.55","bambo":"226.89","low":"226.0","sell":"227.74","vol":"16065.2085"}}'
    json_response_3 = '{"date":"1422679981","ticker":{"buy":"227.27","high":"243.55","last":"null","low":"226.0","sell":"227.74","vol":"16065.2085"}}'
    uri_mock = double('uri mock')
    allow(uri_mock).to receive(:read).with(read_timeout: 4).and_return(json_response_1, json_response_2, json_response_3)
    allow(URI).to      receive(:parse).and_return(uri_mock)
    3.times do
      expect( -> { @exchange_adapter.rate_for('USD') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
    end
  end

end