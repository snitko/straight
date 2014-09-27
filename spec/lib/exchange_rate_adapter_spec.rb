require 'spec_helper'

RSpec.describe Straight::ExchangeRate::Adapter do

  before(:each) do
    @exchange_adapter = Straight::ExchangeRate::Adapter.new
    allow(@exchange_adapter).to receive(:rate_for).with('USD').and_return(450.5412)
  end

  it "converts amount from currency into BTC" do
    expect(@exchange_adapter.convert_from_currency(2252.706, currency: 'USD')).to eq(500000000)
  end

  it "converts from btc into currency" do
    expect(@exchange_adapter.convert_to_currency(500000000, currency: 'USD')).to eq(2252.706)
  end

  it "shows btc amounts in various denominations" do
    expect(@exchange_adapter.convert_from_currency(2252.706, currency: 'USD', btc_denomination: :btc)).to eq(5)
    expect(@exchange_adapter.convert_to_currency(5, currency: 'USD', btc_denomination: :btc)).to eq(2252.706)
  end

end
