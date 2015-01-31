require 'spec_helper'

RSpec.describe Straight::ExchangeRate::BtceAdapter do

  before(:each) do
    @exchange_adapter = Straight::ExchangeRate::BtceAdapter.new
  end

  it "finds the rate for currency code" do
    expect(@exchange_adapter.rate_for('USD')).to be_kind_of(Float)
    expect( -> { @exchange_adapter.rate_for('FEDcoin') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
  end

  it "rases exception if rate is nil" do
    json_response_1 = '{"ticker":{}}'
    json_response_2 = '{{"ticker":{"high":235,"low":215.89999,"avg":225.449995,"vol":2848293.72397,"vol_cur":12657.55799,"bambo":221.444,"buy":221.629,"sell":220.98,"updated":1422678812,"server_time":1422678813}}'
    json_response_3 = '{{"ticker":{"high":235,"low":215.89999,"avg":225.449995,"vol":2848293.72397,"vol_cur":12657.55799,"last":null,"buy":221.629,"sell":220.98,"updated":1422678812,"server_time":1422678813}}'
    uri_mock = double('uri mock')
    allow(uri_mock).to receive(:read).with(read_timeout: 4).and_return(json_response_1, json_response_2, json_response_3)
    allow(URI).to      receive(:parse).and_return(uri_mock)
    3.times do
      expect( -> { @exchange_adapter.rate_for('USD') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
    end
  end

end