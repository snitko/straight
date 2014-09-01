require 'spec_helper'

RSpec.describe Straight::Gateway do

  it "passes methods on to the available adapter" do
    
    mock_adapter = double("mock blockchain adapter")
    
    gateway = Straight::Gateway.new(pubkey: 'pubkey', keep_orders_in_memory: true, blockchain_adapters: [mock_adapter])
    
    expect(mock_adapter).to receive(:fetch_transaction).once 
    expect(mock_adapter).to receive(:fetch_transactions_for).once 
    expect(mock_adapter).to receive(:fetch_balance_for).once 
    
    gateway.fetch_transaction("txid")
    gateway.fetch_transactions_for("address")
    gateway.fetch_balance_for("address")
  end

  it "uses the next availabale adapter when something goes wrong with the current one" do
    mock_adapter = double("mock blockchain adapter")
    another_mock_adapter = double("another_mock blockchain adapter")
    
    gateway = Straight::Gateway.new(pubkey: 'pubkey', keep_orders_in_memory: true, blockchain_adapters: [mock_adapter, another_mock_adapter])
    
    allow(mock_adapter).to receive(:fetch_transaction).once.and_raise(Exception)
    allow(mock_adapter).to receive(:fetch_transactions_for).once.and_raise(Exception)
    allow(mock_adapter).to receive(:fetch_balance_for).once.and_raise(Exception)
        
    expect(another_mock_adapter).to receive(:fetch_transaction).once 
    expect(another_mock_adapter).to receive(:fetch_transactions_for).once 
    expect(another_mock_adapter).to receive(:fetch_balance_for).once 
    
    gateway.fetch_transaction("txid")
    gateway.fetch_transactions_for("address")
    gateway.fetch_balance_for("address")
  end

  it "creates new orders and increments next_address_index" do
    
    gateway = Straight::Gateway.new(pubkey: 'pubkey', keep_orders_in_memory: true)
    
    gateway.create_order(1)
    expect(gateway.orders.size).to eq(1)
    expect(gateway.instance_variable_get('@next_address_index')).to eq(2)
  end

end
