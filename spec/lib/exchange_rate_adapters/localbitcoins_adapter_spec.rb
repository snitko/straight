require 'spec_helper'

RSpec.describe Straight::ExchangeRate::LocalbitcoinsAdapter do

  before(:each) do
    @exchange_adapter = Straight::ExchangeRate::LocalbitcoinsAdapter.new
  end

  it "finds the rate for currency code" do
    expect(@exchange_adapter.rate_for('USD')).to be_kind_of(Float)
    expect( -> { @exchange_adapter.rate_for('FEDcoin') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
  end

  it "rases exception if rate is nil" do
    uri_mock = double('uri mock')
    allow(uri_mock).to receive(:read).with(read_timeout: 4).and_return(nil)
    allow(URI).to       receive(:parse).and_return(uri_mock)
    allow(@exchange_adapter).to receive(:fetch_rates!)
    expect( -> { @exchange_adapter.rate_for('USD') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
  end

end