require 'spec_helper'

RSpec.describe Straight::ExchangeRate::BitpayAdapter do

  before :all do
    VCR.insert_cassette 'exchange_rate_bitpay_adapter'
  end

  after :all do
    VCR.eject_cassette
  end

  before(:each) do
    @exchange_adapter = Straight::ExchangeRate::BitpayAdapter.instance
  end

  it "finds the rate for currency code" do
    expect(@exchange_adapter.rate_for('USD')).to be_kind_of(Float)
    expect( -> { @exchange_adapter.rate_for('FEDcoin') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
  end

  it "raises exception if rate is nil" do
    json_response_1 = '[{},{}]'
    json_response_2 = '[{"code":"USD","name":"US Dollar","rat":223.59},{"code":"EUR","name":"Eurozone Euro","rate":197.179544}]'
    json_response_3 = '[{"code":"USD","name":"US Dollar","rate":null},{"code":"EUR","name":"Eurozone Euro","rate":197.179544}]'
    uri_mock = double('uri mock')
    allow(uri_mock).to receive(:read).with(read_timeout: 4).and_return(json_response_1, json_response_2, json_response_3)
    allow(URI).to      receive(:parse).and_return(uri_mock)
    3.times do
      @exchange_adapter.fetch_rates!
      expect( -> { @exchange_adapter.rate_for('USD') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
    end
  end

end
