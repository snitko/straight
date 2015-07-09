require 'spec_helper'

RSpec.describe Straight::Blockchain::InsightAdapter do

  subject(:mainnet_adapter) { Straight::Blockchain::InsightAdapter.mainnet_adapter("https://insight.mycelium.com/api") }

  before :all do
    VCR.insert_cassette 'blockchain_insight_adapter'
  end

  after :all do
    VCR.eject_cassette
  end

  let(:tid) { 'b168b57a9ae38c0671c5eef3be6c8305782bd1351e75028dac491185388d5424' }

  it "fetches a single transaction" do
    expect(mainnet_adapter.fetch_transaction(tid)[:total_amount]).to eq(499900000)
  end

  it "returns correct prepared data" do
    expect(mainnet_adapter.fetch_transaction(tid)[:total_amount]).to eq(499900000)
    expect(mainnet_adapter.fetch_transaction(tid)[:tid]).to eq("b168b57a9ae38c0671c5eef3be6c8305782bd1351e75028dac491185388d5424")
    expect(mainnet_adapter.fetch_transaction(tid)[:outs].first[:amount]).to eq(187000000)
  end

  it "fetches first transaction for the given address"  do
    address = "1CBWzY7PEnUtT4b36bth4UZuNmby9pTT7A"
    expect(mainnet_adapter.fetch_transactions_for(address)).to be_kind_of(Array)
    expect(mainnet_adapter.fetch_transactions_for(address)).not_to be_empty
  end

  it "fetches balance for given address" do
    address = "16iKJsRM3LrA4k7NeTQbCB9ZDpV64Fkm6"
    expect(mainnet_adapter.fetch_balance_for(address)).to eq(0)
  end

  it "raises exception if something wrong with network" do
    expect( -> { mainnet_adapter.send(:api_request, "/a-404-request", "tid") }).to raise_error(Straight::Blockchain::Adapter::RequestError)
  end

  it "raises exception if worng host_url" do
    adapter = Straight::Blockchain::InsightAdapter.mainnet_adapter("https://insight.mycelium.com/wrong_api")
    expect{ adapter.fetch_transaction(tid)[:total_amount] }.to raise_error(Straight::Blockchain::Adapter::RequestError)
  end
  
end
