require 'spec_helper'

RSpec.describe StraightEngine::BlockchainAdapter::HelloblockIo do

  subject(:adapter) { StraightEngine::BlockchainAdapter::HelloblockIo }

  it "fetches all transactions for the current address" do
    address = "3B1QZ8FpAaHBgkSB5gFt76ag5AW9VeP8xp"
    expect(adapter.fetch_transactions_for(address)).not_to be_empty
  end

  it "fetches the balance for a given address" do
    address = "3B1QZ8FpAaHBgkSB5gFt76ag5AW9VeP8xp"
    expect(adapter.fetch_balance_for(address)).to be_kind_of(Integer)
  end

  it "fetches a single transaction" do
    tid = 'ae0d040f48d75fdc46d9035236a1782164857d6f0cca1f864640281115898560'
    expect(adapter.fetch_transaction(tid)[:total_amount]).to eq(832947)
  end

  it "returns the number of confirmations for a transaction" do
    tid = 'ae0d040f48d75fdc46d9035236a1782164857d6f0cca1f864640281115898560'
    expect(adapter.fetch_transaction(tid)[:confirmations]).to be > 0
  end

  it "raises an exception when something goes wrong with fetching datd" do
    allow_any_instance_of(URI).to receive(:read).and_raise(OpenURI::HTTPError)
    expect( -> { adapter.http_request("http://blockchain.info/a-timed-out-request") }).to raise_error(StraightEngine::BlockchainAdapter::RequestError)
  end

end
