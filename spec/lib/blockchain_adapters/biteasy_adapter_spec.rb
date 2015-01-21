require 'spec_helper'
# require 'byebug'; debugger

RSpec.describe Straight::Blockchain::BiteasyAdapter do

  subject(:adapter) { Straight::Blockchain::BiteasyAdapter.mainnet_adapter }

  it "fetches the balance for a given address" do
    address = "3B1QZ8FpAaHBgkSB5gFt76ag5AW9VeP8xp"
    expect(adapter.fetch_balance_for(address)).to be_kind_of(Integer)
  end

  it "fetches a single transaction" do
    tid = 'ae0d040f48d75fdc46d9035236a1782164857d6f0cca1f864640281115898560'
    expect(adapter.fetch_transaction(tid)[:total_amount]).to eq(832947)
  end

  it "calculates total_amount of a transaction for the given address only" do
    t = { 'data' => {'outputs' => [{ 'value' => 1, 'to_address' => 'address1'}, { 'value' => 2, 'to_address' => 'address2'}] } }
    expect(adapter.send(:straighten_transaction, t, address: 'address1')[:total_amount]).to eq(1)
  end

  it "fetches all transactions for the current address" do
    address = "3B1QZ8FpAaHBgkSB5gFt76ag5AW9VeP8xp"
    expect(adapter).to receive(:straighten_transaction).with(anything, address: address).at_least(:once)
    expect(adapter.fetch_transactions_for(address)).not_to be_empty
  end

end