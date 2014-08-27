require 'spec_helper'

RSpec.describe StraightEngine::BlockchainAdapter do

  subject(:adapter) { StraightEngine::BlockchainAdapter.new }

  before(:each) do
    subject.instance_variable_set('@adapters', [])
    @mock_adapter = double("mock blockchain adapter")
    adapter.register_adapter(@mock_adapter)
  end

  it "passes methods on to the available adapter" do
    expect(@mock_adapter).to receive(:hello).once 
    adapter.hello
  end

  it "uses the next availabale adapter when something goes wrong with the current one" do
    another_mock_adapter = double("another_mock blockchain adapter")
    adapter.register_adapter(another_mock_adapter)
    allow(@mock_adapter).to receive(:hello).once.and_raise(Exception) 
    expect(another_mock_adapter).to receive(:hello).once 
    adapter.hello
  end

end
