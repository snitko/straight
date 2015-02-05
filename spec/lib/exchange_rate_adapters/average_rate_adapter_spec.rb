require 'spec_helper'

RSpec.describe Straight::ExchangeRate::AverageRateAdapter do

  before(:all) do
    @average_rates_adapter =  Straight::ExchangeRate::AverageRateAdapter.new(
                                Straight::ExchangeRate::BitstampAdapter, 
                                Straight::ExchangeRate::BitpayAdapter.new,
                              )
  end

  it "calculates average rate" do
    expect(@average_rates_adapter.rate_for('USD')).to be_kind_of Numeric
  end

  it "raises exception if all adapters fail to get rates" do
    expect( -> { @average_rates_adapter.rate_for('FEDcoin') }).to raise_error(Straight::ExchangeRate::Adapter::CurrencyNotSupported)
  end

  it "raises exception if unallowed method is called" do # fetch_rates! is not to be used in AverageRateAdapter itself
    expect( -> { @average_rates_adapter.fetch_rates! }).to raise_error("This method is not supposed to be used in #{@average_rates_adapter.class}.")
  end

end