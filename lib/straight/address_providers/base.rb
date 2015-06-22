module Straight
  module AddressProvider
    class Base

      attr_reader :gateway

      def initialize(gateway)
        @gateway = gateway
      end

      # @param [Hash] args see GatewayModule::Includable#new_order
      # @return [String] bitcoin address
      # Returns a Base58-encoded Bitcoin address to which the payment transaction
      # is expected to arrive. keychain_id is an integer > 0 (hopefully not too large and hopefully
      # the one a user of this class is going to properly increment) that is used to generate a
      # an BIP32 bitcoin address deterministically.
      def new_address(keychain_id:, **args)
        raise NotImplementedError
      end

      # If this method returns true, then address provider is expected to define
      # #new_address_and_amount which returns ['address', Integer(amount in satoshi)]
      def takes_fees?
        false
      end
    end
  end
end
