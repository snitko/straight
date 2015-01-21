require 'spec_helper'

RSpec.describe Straight::Blockchain::BkchainAdapter do

  subject(:adapter) { Straight::Blockchain::BkchainAdapter.mainnet_adapter }
  # fix/decide with that one API: https://bkchain.org/static/api.txt
  it "fetches all transactions for the current address" do
    pending 'cant find api request to get that info, pls verify and remove this
     test with #fetch_transactions_for for this adapter if api https://bkchain.org/static/api.txt doesnt have it'
    address = "3B1QZ8FpAaHBgkSB5gFt76ag5AW9VeP8xp"
    expect(adapter).to receive(:straighten_transaction).with(anything, address: address).at_least(:once)
    expect(adapter.fetch_transactions_for(address)).not_to be_empty
  end
  
  it "fetches the balance for a given address" do
    # can it be negative? Why it gives zeros for all adresses
    # mine really has ballance 0
    # https://bkchain.org/bitcoin/api/v1/address/balance/1A22t4W8VeMzoRJFFWgiWGGXiwszi2N9Bb?confirmations=3
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

  it "gets a transaction id among other data" do
    tid = 'ae0d040f48d75fdc46d9035236a1782164857d6f0cca1f864640281115898560'
    expect(adapter.fetch_transaction(tid)[:tid]).to eq(tid)
  end
  
  it "returns the number of confirmations for a transaction" do
    tid = 'ae0d040f48d75fdc46d9035236a1782164857d6f0cca1f864640281115898560'
    expect(adapter.fetch_transaction(tid)[:confirmations]).to be > 0
  end

  it "raises an exception when something goes wrong with fetching datd" do
    allow_any_instance_of(URI::HTTPS).to receive(:read).and_raise(OpenURI::HTTPError.new('https connection error', nil))
    expect( -> { adapter.http_request("https://blockchain.info/a-timed-out-request") }).to raise_error(Straight::Blockchain::Adapter::RequestError)
  end

  it "calculates total_amount of a transaction for the given address only" do
    t = { 'outs' => [{ 'v' => 1, 'addr' => 'address1'}, { 'v' => 1, 'addr' => 'address2'}] }
    expect(adapter.send(:straighten_transaction, t, address: 'address1')[:total_amount]).to eq(1)
  end

end
