require 'spec_helper'

RSpec.describe Straight::Gateway do

  subject(:gateway) { Straight::Gateway.new(pubkey: 'pubkey') }

  before(:each) do
    @mock_adapter = double("mock blockchain adapter")
  end

  it "passes methods on to the available adapter" do
    gateway.instance_variable_set('@blockchain_adapters', [@mock_adapter])
    expect(@mock_adapter).to receive(:fetch_transaction).once 
    gateway.fetch_transaction("xxx")
  end

  it "uses the next availabale adapter when something goes wrong with the current one" do
    another_mock_adapter = double("another_mock blockchain adapter")
    gateway.instance_variable_set('@blockchain_adapters', [@mock_adapter, another_mock_adapter])
    allow(@mock_adapter).to receive(:fetch_transaction).once.and_raise(Exception) 
    expect(another_mock_adapter).to receive(:fetch_transaction).once 
    gateway.fetch_transaction("xxx")
  end

  it "creates new orders and addresses for them" do
    gateway.pubkey   = MoneyTree::Master.new.to_serialized_address 
    expected_address = MoneyTree::Node.from_serialized_address(gateway.pubkey).node_for_path("1").to_address
    expect(gateway.order_for_id(amount: 1, pubkey_id: 1).address).to eq(expected_address)
  end

end
