require_relative 'base'

module Straight
  module AddressProvider
    class Bip32 < Base
      def new_address(keychain_id:, **args)
        if gateway.address_derivation_scheme.to_s.empty?
          # First check the depth. If the depth is 4 use '/i' notation (Mycelium iOS wallet)
          # TODO deal with other depths later. Currently only supports 0 and 4
          if gateway.keychain.depth > 3
            gateway.keychain.node_for_path(keychain_id.to_s).to_address
          else # Otherwise, use 'm/0/n' - both Electrum and Mycelium on Android
            gateway.keychain.node_for_path("m/0/#{keychain_id.to_s}").to_address
          end
        else
          gateway.keychain.node_for_path(
            gateway.address_derivation_scheme.to_s.downcase.sub('n', keychain_id.to_s)
          ).to_address
        end
      end
    end
  end
end
