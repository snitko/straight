require 'spec_helper'

RSpec.describe Straight::Blockchain::MyceliumAdapter do

  subject(:adapter) { Straight::Blockchain::MyceliumAdapter.mainnet_adapter }

  before :all do
    VCR.insert_cassette 'blockchain_mycelium_adapter'
  end

  after :all do
    VCR.eject_cassette
  end

  it "fetches all transactions for the current address" do
    address = "3B1QZ8FpAaHBgkSB5gFt76ag5AW9VeP8xp"
    expect(adapter).to receive(:straighten_transaction).with(anything, address: address).at_least(:once)
    expect(adapter.fetch_transactions_for(address)).not_to be_empty
  end

  it "fetches the balance for a given address" do
    address = "1NX8bgWdPq2NahtTbTUAAdsTwpMpvt7nLy"
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

  it "gets a transaction id among other data" do
    tid = 'ae0d040f48d75fdc46d9035236a1782164857d6f0cca1f864640281115898560'
    expect(adapter.fetch_transaction(tid)[:tid]).to eq(tid)
  end

  it "gets the latest block number" do
    expect(adapter.latest_block[:block]["height"]).to be_kind_of(Integer)
  end

  it "caches latestblock requests" do
    latest_block_response = double('Blockchain info latest block response')
    expect(latest_block_response).to receive(:body).and_return('{ "r": { "height": 1 }}') 
    expect(HTTParty).to receive(:post).with("https://mws2.mycelium.com/wapi/wapi/queryUnspentOutputs", anything).once.and_return(latest_block_response)
    adapter.send(:calculate_confirmations, 1, force_latest_block_reload: true)
    adapter.send(:calculate_confirmations, 1)
    adapter.send(:calculate_confirmations, 1)
    adapter.send(:calculate_confirmations, 1)
    adapter.send(:calculate_confirmations, 1)
  end
  
  it "raises an exception when something goes wrong with fetching datd" do
    expect( -> { adapter.send(:api_request, "/a-404-request") }).to raise_error(Straight::Blockchain::Adapter::RequestError)
  end

  # For now disable singleton instances for adapters
  # it "uses the same Singleton instance" do
  #   a = Straight::Blockchain::MyceliumAdapter.mainnet_adapter
  #   b = Straight::Blockchain::MyceliumAdapter.mainnet_adapter
  #   expect(a).to eq(b)
  # end

  it "using next server if previous failed" do
    block_response = double('Blockchain info latest block response')
    expect(block_response).to receive(:body).and_return('{ "r": { "height": 1 }}') 
    expect(HTTParty).to receive(:post).with(Straight::Blockchain::MyceliumAdapter::MAINNET_SERVERS[0]+"/queryUnspentOutputs", anything).once.and_raise(HTTParty::Error)
    expect(HTTParty).to receive(:post).with(Straight::Blockchain::MyceliumAdapter::MAINNET_SERVERS[1]+"/queryUnspentOutputs", anything).once.and_return(block_response)
    adapter.send(:calculate_confirmations, 1)
    expect(adapter.instance_variable_get(:@base_url)).to eq(Straight::Blockchain::MyceliumAdapter::MAINNET_SERVERS[1])
  end

  it "raise errors if all servers failed" do
    Straight::Blockchain::MyceliumAdapter::MAINNET_SERVERS.each do |s|
      expect(HTTParty).to receive(:post).with(s + "/queryUnspentOutputs", anything).once.and_raise(HTTParty::Error)
    end
    expect {
      adapter.send(:calculate_confirmations, 1)
    }.to raise_error(Straight::Blockchain::Adapter::RequestError)
  end
  
  it "fetches data from testnet for specific address" do
    VCR.use_cassette "wapitestnet" do
      adapter = Straight::Blockchain::MyceliumAdapter.testnet_adapter
      address = "mjRmkmYzvZN3cA3aBKJgYJ65epn3WCG84H"
      expect(adapter).to receive(:straighten_transaction).with(anything, address: address).at_least(:once).and_return(1)
      expect(adapter.fetch_transactions_for(address)).to eq([1])
    end
  end

end
