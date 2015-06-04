require 'spec_helper'

RSpec.describe Straight::AddressProvider::Bip32 do

  before(:each) do
    @mock_adapter                  = double("mock blockchain adapter")
    @gateway                       = Straight::Gateway.new
    @gateway.pubkey                = "pubkey"
    @gateway.order_class           = "Straight::Order"
    @gateway.blockchain_adapters   = [@mock_adapter]
    @gateway.status_check_schedule = Straight::Gateway::DEFAULT_STATUS_CHECK_SCHEDULE
    @gateway.order_callbacks       = []
  end

  it "checks the depth of the xpub key and uses derivation notation according to the depth" do
    @gateway.pubkey = 'xpub6DkF8MtNnbJY6NBR5tBSZ2NYQL16sT4fiT1R8U4D24bfSNmzzbhzNdP25LLgmis6c7EsVdzdUqv1MZoU8TNHaNNRHfTE1hqXRNMfPyJ2fCw'
    expect(Straight::AddressProvider::Bip32.new_address(
      { keychain_id: 0 }, @gateway
    )).to eq("1GS7KMkpz27xpFKddFPkjqCAAPPo9eyUev")
  end

  it "uses address_derivation_scheme if it's not blank" do
    @gateway.pubkey = 'xpub6DkF8MtNnbJY6NBR5tBSZ2NYQL16sT4fiT1R8U4D24bfSNmzzbhzNdP25LLgmis6c7EsVdzdUqv1MZoU8TNHaNNRHfTE1hqXRNMfPyJ2fCw'
    @gateway.address_derivation_scheme = 'n'
    expect(Straight::AddressProvider::Bip32.new_address({keychain_id: 0}, @gateway)).to eq "1GS7KMkpz27xpFKddFPkjqCAAPPo9eyUev"
    @gateway.address_derivation_scheme = 'm/0/n'
    expect(Straight::AddressProvider::Bip32.new_address({keychain_id: 0}, @gateway)).to eq "18SKUD8J2K6YPHkchmxYavw9QgeQ8MRJik"
    @gateway.address_derivation_scheme = 'M/0/N'
    expect(Straight::AddressProvider::Bip32.new_address({keychain_id: 0}, @gateway)).to eq "18SKUD8J2K6YPHkchmxYavw9QgeQ8MRJik"
  end
end
