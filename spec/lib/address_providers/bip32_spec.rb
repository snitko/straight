require 'spec_helper'

RSpec.describe Straight::AddressProvider::Bip32 do

  before :each do
    @gateway = Straight::Gateway.new
    @bip32   = described_class.new(@gateway)
  end

  it "checks the depth of the xpub key and uses derivation notation according to the depth" do
    xpubs_by_depth     = [
      'xpub661MyMwAqRbcFpmhdatYB5jtFnDCzAwM4trP5CvpH76sbDwEDr65ZLeoabjvZ74QJvLr85WQtpzsNE438ci8niFjLYfFL9ARMZvRyp6zBnZ', # BTC::Keychain.new(seed: 'test'), depth 0
      'xpub696oZHFwkKZvnVw7D5N7ZuBVPZEhAZiJ4k39LszPtTF6fqHUgwhUhsKm87UVJ9ESugNxE16kBWqghHz8X7FYgMWjWLZDqGb2TprJu3DCdBB', # derived_keychain(0), depth 1
      'xpub69yG7yz3Hw3uYvdEuW7vA6ovtQ873iLQvEuaLKUr7JEkK3NJ2G5ScS3CsiaXHpSauno5f7QVYfe8QKBSeGd8u3HSTxHjTxVwwJHXd9tBZh1', # derived_keychain(0), depth 2
      'xpub6Bz6sYpLBA6PvDnmUsehRbUNmJWD8gWTg1Fuopyn7ChGRDZU7VNwBJMVFYZBwcSeHNJVPme1XQzBscwNzVk3eyByVfwY2sUM3BP1PQnHtK5', # derived_keychain(0), depth 3
      'xpub6F1nL3gg1CJCbaCvqrDekgueaZaBjxwgMucarAJjuLcPVhMfgv4EzGU8Nj4MsmVAGdUASqEU9qFLG3PPRukLwystu1pdSLWkujmDQ4X43Dk', # derived_keychain(0), depth 4
      'xpub6FwAPiwmPXe2a1zVkASULH1o3PYg7YRU32p2onywjqntCKuPZhotjemCrxjGymrcobVZu7Esfrs6eemuU7LhquLbuzHChYRz8R7q563AQFn', # derived_keychain(0), depth 5
    ]
    expected_addresses = [
      '158nkHoQi9cNUEj2aefHWX9UYR1aqNG88Q', # derived_key('m/0/0')
      '1KN9CJvJGeM7z87jdze8kvdab1si5oMeDn', # derived_key('m/0/0')
      '17ScZf5WF2sPpjAo9MR5PLPNqBkrm4XrwC', # derived_key('m/0/0')
      '16uPb94ook3D5hXGpobyjaEnVznvYN3hMn', # derived_key('m/0/0')
      '16uPb94ook3D5hXGpobyjaEnVznvYN3hMn', # derived_key('0')
      '1nFN9omP2qkYeHPLgKXG5Eq2bFmGNift2', # derived_key('0')
    ]
    xpubs_by_depth.each_with_index do |xpub, i|
      @gateway.instance_variable_set :@keychain, nil
      @gateway.pubkey = xpub
      expect(@bip32.new_address(keychain_id: 0)).to eq expected_addresses[i]
    end
  end

  it "uses address_derivation_scheme if it's not blank" do
    @gateway.pubkey                    = 'xpub661MyMwAqRbcFpmhdatYB5jtFnDCzAwM4trP5CvpH76sbDwEDr65ZLeoabjvZ74QJvLr85WQtpzsNE438ci8niFjLYfFL9ARMZvRyp6zBnZ'
    @gateway.address_derivation_scheme = 'n'
    expect(@bip32.new_address(keychain_id: 0)).to eq "13VDxG5Dh7mb8c3ji7RZDgjKeYGHfxkyyz"
    @gateway.address_derivation_scheme = 'm/0/n'
    expect(@bip32.new_address(keychain_id: 0)).to eq "158nkHoQi9cNUEj2aefHWX9UYR1aqNG88Q"
    @gateway.address_derivation_scheme = 'M/0/N'
    %w{
      158nkHoQi9cNUEj2aefHWX9UYR1aqNG88Q
      1Fan3Zb9Co6tjYdHDtBSHoi1xVF9eCfU2e
      19FbGA3W16xXd8eJA2rwHUZSSkUwTQC4aZ
      15NzdZeqrbsNqvKoy9rPSBXKUtVWfv8NfQ
      113AtyN4MrF1347eDpwwFyxSsoz7S85Evc
      13z5RZXCm3sEShf4idLBELxcxMWXkU6Eve
      1FZoUZ2oHSMjboJoFbV7sPopyHN3A4yYCo
      14YWFJjU7nGdsq8MrqX1aZKjmF8hdUW38U
      1DBVG6RiWh72T3W3C3WjzoFAzSK7VvA3v5
      1NiNoaeUEzhCP8xgAALXkx5sRPLmsTdNVn
      1Lg9w6vAoUW4aQ28AThssa7TTKaT79gH9t
      1LtePLSBD5ZxPFqgKBWkETXu5P9rMJJnrP
      1BDRKTnExpdV1aeprrVN8TZsEHndHMhzhA
      18hyL5bww1ZqFgPeWze1xuF86DdKqkQzUS
      1BBuDxo22CMFiWcoc4h7MRHCQ4LbMaiGLe
      19H8nGPcgM7QLFqn3Xr1WzjmVadkJhxjUw
      1HzLnz5D7qADJpePFSeArDaGwdWyfnBbCo
      15TVMTWbKKrqi1Zn2CHR36BLogNXDR37Vm
      1L6mGCZXmN9qDUbupSa2DEcu9haYTeSwUX
      1BcSPUisV1B4pskvJb2AGjis65QF1UfqZv
    }.each_with_index do |address, i|
      expect(@bip32.new_address(keychain_id: i)).to eq address
    end
  end
end
