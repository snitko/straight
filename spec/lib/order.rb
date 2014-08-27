require 'spec_helper'

RSpec.describe StraightEngine::Order do

  it "follows status check schedule" do
    order = StraightEngine::Order.new(amount: 1, pubkey: 'pubkey')
    [10, 20, 40, 80, 160, 320, 640].each do |i|
      expect(order).to receive(:sleep).with(i).exactly(6).times
    end
    order.check_status_on_schedule
  end

  it "gets the last transaction for the current address" do
  end

  it "gets all transactions for the current address" do
  end

end
