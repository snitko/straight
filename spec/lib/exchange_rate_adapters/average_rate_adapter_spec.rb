require 'spec_helper'

RSpec.describe Straight::ExchangeRate::AverageRateAdapter do

  before(:all) do
    @average_rates_adapter =  Straight::ExchangeRate::AverageRateAdapter.new(
                                Straight::ExchangeRate::BitstampAdapter.new, 
                                Straight::ExchangeRate::BitpayAdapter.new)
  end

  it "calculates average rate" do
    @average_rates_adapter.calculate_avg_rate
  end

end