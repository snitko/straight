require_relative 'base'

module Straight
  module AddressProvider
    class Bip32 < Base
      def new_address(keychain_id:, **args)
        path =
          if gateway.address_derivation_scheme.to_s.empty?
            # First check the depth. If the depth is 4 use '/i' notation (Mycelium iOS wallet)
            if gateway.keychain.depth > 3
              keychain_id.to_s
            else # Otherwise, use 'm/0/n' - both Electrum and Mycelium on Android
              "m/0/#{keychain_id.to_s}"
            end
          else
            gateway.address_derivation_scheme.to_s.downcase.sub('n', keychain_id.to_s)
          end
        gateway.keychain.derived_key(path).address.to_s
      end
    end
  end
end
