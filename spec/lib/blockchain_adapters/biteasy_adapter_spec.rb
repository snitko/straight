require 'spec_helper'

RSpec.describe Straight::Blockchain::BiteasyAdapter do

  subject(:adapter) { Straight::Blockchain::BiteasyAdapter.mainnet_adapter }

  it "fetches the balance for a given address" do
    address = "3B1QZ8FpAaHBgkSB5gFt76ag5AW9VeP8xp"
    expect(adapter.fetch_balance_for(address)).to be_kind_of(Integer)
  end

end