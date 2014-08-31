require 'spec_helper'

RSpec.describe Straight::Order do

  before(:each) do
    @gateway = double("Straight Gateway mock")
    @order   = Straight::Order.new(amount: 1, gateway: @gateway)
  end

  it "follows status check schedule" do
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

end
