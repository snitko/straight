require 'spec_helper'

RSpec.describe Straight::Order do

  subject(:order) { Straight::Order.new(amount: 1, pubkey: 'pubkey') }

  it "follows status check schedule" do
    [10, 20, 40, 80, 160, 320, 640].each do |i|
      expect(order).to receive(:sleep).with(i).exactly(6).times
    end
    order.check_status_on_schedule
  end

  it "gets the last transaction for the current address, caches the request" do
    expect(Straight::BlockchainAdapter).to receive(:method_missing).with(:fetch_transactions_for, subject.address).once.and_return(true)
    subject.transactions
    subject.transactions
  end

  it "gets all transactions for the current address, caches the request" do
    expect(Straight::BlockchainAdapter).to receive(:method_missing).with(:fetch_transactions_for, subject.address).once.and_return(['t1', 't2'])
    expect(subject.transaction).to eq('t1')
    expect(subject.transaction).to eq('t1')
  end

end
