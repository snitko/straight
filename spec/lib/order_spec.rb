require 'spec_helper'

RSpec.describe Straight::Order do

  before(:each) do
    @gateway = double("Straight Gateway mock")
    @order   = Straight::Order.new(amount: 10, gateway: @gateway, address: 'address')
  end

  it "follows status check schedule" do
    allow(@gateway).to receive(:fetch_transactions_for).with('address').and_return([])
    allow(@gateway).to receive(:status_check_schedule).and_return(Straight::Gateway::DEFAULT_STATUS_CHECK_SCHEDULE)
    [10, 20, 40, 80, 160, 320, 640].each do |i|
      expect(@order).to receive(:sleep).with(i).exactly(6).times
    end
    @order.check_status_on_schedule
  end

  it "gets the last transaction for the current address, caches the request" do
    expect(@gateway).to receive(:fetch_transactions_for).with(@order.address).once.and_return(true)
    @order.transactions
    @order.transactions
  end

  it "gets all transactions for the current address, caches the request" do
    expect(@gateway).to receive(:fetch_transactions_for).with(@order.address).once.and_return(['t1', 't2'])
    expect(@order.transaction).to eq('t1')
    expect(@order.transaction).to eq('t1')
  end

  describe "assigning statuses" do

    before(:each) do
      allow(@gateway).to receive(:confirmations_required).and_return(1)
    end

    it "doesn't reload the transaction unless forced" do
      @order.instance_variable_set(:@status, true)
      expect(@order).to_not receive(:transaction)
      @order.status
    end

    it "sets status to :new if no transaction issued" do
      expect(@order).to receive(:transaction).and_return(nil)
      expect(@order.status).to eq(0)
    end

    it "sets status to :unconfirmed if transaction doesn't have enough confirmations" do
      transaction = { confirmations: 0 }
      expect(@order).to receive(:transaction).and_return(transaction)
      expect(@order.status).to eq(1)
    end

    it "sets status to :paid if transaction has enough confirmations and the amount is correct" do
      transaction = { confirmations: 1, total_amount: @order.amount }
      expect(@order).to receive(:transaction).and_return(transaction)
      expect(@order.status).to eq(2)
    end

    it "sets status to :underpaid if the total amount in a transaction is less than the amount of order" do
      transaction = { confirmations: 1, total_amount: @order.amount-1 }
      expect(@order).to receive(:transaction).and_return(transaction)
      expect(@order.status).to eq(3)
    end

    it "sets status to :overderpaid if the total amount in a transaction is more than the amount of order" do
      transaction = { confirmations: 1, total_amount: @order.amount+1 }
      expect(@order).to receive(:transaction).and_return(transaction)
      expect(@order.status).to eq(4)
    end

  end

end
