require 'spec_helper'

RSpec.describe Straight::ExchangeRate::OkcoinAdapter do

  before :all do
    VCR.insert_cassette 'exchange_rate_okcoin_adapter'
  end

  after :all do
    VCR.eject_cassette
  end

  before(:each) do
    @exchange_adapter = Straight::ExchangeRate::OkcoinAdapter.instance
  end

  it "finds the rate for currency code" do
    expect(@exchange_adapter.rate_for('USD')).to be_kind_of(Float)
    expect( -> { @exchange_adapter.rate_for('FEDcoin') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
  end

  it "raises exception if rate is nil" do
    response = [
      '{"date":"1422679981","ticker":{}}',
      '{"date":"1422679981","ticker":{"buy":"227.27","high":"243.55","bambo":"226.89","low":"226.0","sell":"227.74","vol":"16065.2085"}}',
      '{"date":"1422679981","ticker":{"buy":"227.27","high":"243.55","last":null,"low":"226.0","sell":"227.74","vol":"16065.2085"}}',
    ]
    3.times do |i|
      @exchange_adapter.instance_variable_set :@rates_updated_at, Time.now
      @exchange_adapter.instance_variable_set :@rates, JSON.parse(response[i])
      expect( -> { @exchange_adapter.rate_for('USD') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
    end
  end

end
