require 'spec_helper'

RSpec.describe Straight::ExchangeRate::AverageRateAdapter do

  before(:all) do
    @average_rates_adapter =  Straight::ExchangeRate::AverageRateAdapter.new(
                                Straight::ExchangeRate::BitstampAdapter.new, 
                                Straight::ExchangeRate::BitpayAdapter.new)
  end

  it "calculates average rate" do
    expect(@average_rates_adapter.calculate_avg_rate).to be_kind_of Numeric
    @average_rates_adapter.instance_variable_set('@rates', [8, nil, 2])
    expect(@average_rates_adapter.calculate_avg_rate).to eq 5
  end

end