require 'spec_helper'

RSpec.describe StraightEngine::BlockchainAdapter::BlockchainInfo do

  subject(:adapter) { StraightEngine::BlockchainAdapter::BlockchainInfo }

  it "fetches all transactions for the current address" do
    tid = 'ae0d040f48d75fdc46d9035236a1782164857d6f0cca1f864640281115898560'
    expect(adapter.fetch_transaction(tid)[:total_amount]).to eq(832947)
  end

  it "fetches a single transaction" do
    address = "3B1QZ8FpAaHBgkSB5gFt76ag5AW9VeP8xp"
    expect(adapter.fetch_transactions_for(address)[:balance]).to eq(21022060)
  end

  it "calculates the number of confirmations for each transaction" do
    tid = 'ae0d040f48d75fdc46d9035236a1782164857d6f0cca1f864640281115898560'
    expect(adapter.fetch_transaction(tid)[:confirmations]).to be > 0
  end

  it "caches blockchain.info latestblock requests" do
    expect(Net::HTTP).to receive(:get).once.and_return('{ "height": 1 }')
    adapter.send(:calculate_confirmations, { "block_height" => 1 }, force_latest_block_reload: true)
    adapter.send(:calculate_confirmations, { "block_height" => 1 })
    adapter.send(:calculate_confirmations, { "block_height" => 1 })
    adapter.send(:calculate_confirmations, { "block_height" => 1 })
    adapter.send(:calculate_confirmations, { "block_height" => 1 })
  end

end
