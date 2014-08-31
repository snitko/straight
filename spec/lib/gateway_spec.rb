require 'spec_helper'

RSpec.describe Straight::Gateway do

  subject(:gateway) { Straight::Gateway.new(pubkey: 'pubkey') }

  before(:each) do
    @mock_adapter = double("mock blockchain adapter")
  end

  it "passes methods on to the available adapter" do
    gateway.instance_variable_set('@blockchain_adapters', [@mock_adapter])
    expect(@mock_adapter).to receive(:fetch_transaction).once 
    gateway.fetch_transaction
  end

  it "uses the next availabale adapter when something goes wrong with the current one" do
    another_mock_adapter = double("another_mock blockchain adapter")
    gateway.instance_variable_set('@blockchain_adapters', [@mock_adapter, another_mock_adapter])
    allow(@mock_adapter).to receive(:fetch_transaction).once.and_raise(Exception) 
    expect(another_mock_adapter).to receive(:fetch_transaction).once 
    gateway.fetch_transaction
  end

end
