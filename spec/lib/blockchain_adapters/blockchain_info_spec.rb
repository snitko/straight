require 'spec_helper'

RSpec.describe Straight::BlockchainAdapter::BlockchainInfo do

  subject(:adapter) { Straight::BlockchainAdapter::BlockchainInfo }

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

  it "calculates the number of confirmations for each transaction" do
    tid = 'ae0d040f48d75fdc46d9035236a1782164857d6f0cca1f864640281115898560'
    expect(adapter.fetch_transaction(tid)[:confirmations]).to be > 0
  end

  it "caches blockchain.info latestblock requests" do
    expect(adapter).to receive(:http_request).once.and_return('{ "height": 1 }')
    adapter.send(:calculate_confirmations, { "block_height" => 1 }, force_latest_block_reload: true)
    adapter.send(:calculate_confirmations, { "block_height" => 1 })
    adapter.send(:calculate_confirmations, { "block_height" => 1 })
    adapter.send(:calculate_confirmations, { "block_height" => 1 })
    adapter.send(:calculate_confirmations, { "block_height" => 1 })
  end
  
  it "raises an exception when something goes wrong with fetching datd" do
    allow_any_instance_of(URI).to receive(:read).and_raise(OpenURI::HTTPError)
    expect( -> { adapter.http_request("http://blockchain.info/a-timed-out-request") }).to raise_error(Straight::BlockchainAdapter::Base::RequestError)
  end

end
