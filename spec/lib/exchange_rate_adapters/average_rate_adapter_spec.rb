require 'spec_helper'

RSpec.describe Straight::ExchangeRate::AverageRateAdapter do

  before :all do
    VCR.insert_cassette 'exchange_rate_average_rate_adapter'
  end

  after :all do
    VCR.eject_cassette
  end

  before(:each) do
    @average_rates_adapter = Straight::ExchangeRate::AverageRateAdapter.instance(
      Straight::ExchangeRate::BitstampAdapter, 
      Straight::ExchangeRate::BitpayAdapter.instance,
    )
  end

  it "calculates average rate" do
    json_response_bistamp = '{"high": "232.89", "last": "100", "timestamp": "1423457015", "bid": "224.00", "vwap": "224.57", "volume": "14810.41127494", "low": "217.28", "ask": "224.13"}'
    json_response_bitpay = '[{"code":"USD","name":"US Dollar","rate":200},{"code":"EUR","name":"Eurozone Euro","rate":197.179544}]'
    uri_mock = double('uri mock')
    allow(uri_mock).to receive(:read).with(read_timeout: 4).and_return(json_response_bistamp, json_response_bitpay)
    allow(URI).to      receive(:parse).and_return(uri_mock)
    expect(@average_rates_adapter.rate_for('USD')).to eq 150
  end

  it "fetches rates for all adapters" do
    expect(@average_rates_adapter.fetch_rates!).not_to be_empty
  end

  it 'raises error if all adapters failed to fetch rates' do
    adapter_mocks = [double('adapter_1'), double('adapter_2')]
    adapter_mocks.each do |adapter|
      expect(adapter).to receive(:fetch_rates!).and_raise(Straight::ExchangeRate::Adapter::FetchingFailed)
    end
    average_rates_adapter = Straight::ExchangeRate::AverageRateAdapter.instance(*adapter_mocks)
    expect( -> { average_rates_adapter.fetch_rates! }).to raise_error(Straight::ExchangeRate::Adapter::FetchingFailed)
  end

  it "raises exception if all adapters fail to get rates" do
    expect( -> { @average_rates_adapter.rate_for('FEDcoin') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
  end

  it "raises exception if unallowed method is called" do # fetch_rates! is not to be used in AverageRateAdapter itself
    expect( -> { @average_rates_adapter.get_rate_value_from_hash(nil, 'nothing') }).to raise_error("This method is not supposed to be used in #{@average_rates_adapter.class}.")
    expect( -> { @average_rates_adapter.rate_to_f(nil) }).to raise_error("This method is not supposed to be used in #{@average_rates_adapter.class}.")
  end

end
