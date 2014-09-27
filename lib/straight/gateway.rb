module Straight

  module GatewayModule

    # Only add getters and setters for those properties in the extended class
    # that don't already have them. This is very useful with ActiveRecord for example
    # where we don't want to override AR getters and setters that set attributes.
    def self.included(base)
      base.class_eval do
        [
          :pubkey,
          :confirmations_required,
          :status_check_schedule,
          :blockchain_adapters,
          :order_callbacks,
          :order_class,
          :name
        ].each do |field|
          attr_reader field unless base.method_defined?(field)
          attr_writer field unless base.method_defined?("#{field}=")
          prepend Prependable
          include Includable
        end
      end
    end

    # Determines the algorithm for consequitive checks of the order status.
    DEFAULT_STATUS_CHECK_SCHEDULE = -> (period, iteration_index) do
      return false if period > 640
      iteration_index += 1
      if iteration_index > 5
        period          *= 2
        iteration_index  = 0
      end
      return { period: period, iteration_index: iteration_index }
    end

    module Prependable
      # Only getters and setters for attributes should be here
    end

    module Includable

      # Creates a new order for the address derived from the pubkey and the keychain_id argument provided.
      # See explanation of this keychain_id argument is in the description for the #address_for_keychain_id method.
      def order_for_keychain_id(amount:, keychain_id:)
        order             = Kernel.const_get(order_class).new
        order.amount      = amount
        order.gateway     = self
        order.address     = address_for_keychain_id(keychain_id)
        order.keychain_id = keychain_id
        order
      end

      # Returns a Base58-encoded Bitcoin address to which the payment transaction
      # is expected to arrive. id is an an integer > 0 (hopefully not too large and hopefully
      # the one a user of this class is going to properly increment) that is used to generate a
      # an BIP32 bitcoin address deterministically.
      def address_for_keychain_id(id)
        keychain.node_for_path(id.to_s).to_address
      end
      
      def fetch_transaction(tid, address: nil)
        try_blockchain_adapters { |b| b.fetch_transaction(tid, address: address) }
      end
      
      def fetch_transactions_for(address)
        try_blockchain_adapters { |b| b.fetch_transactions_for(address) }
      end
      
      def fetch_balance_for(address)
        try_blockchain_adapters { |b| b.fetch_balance_for(address) }
      end

      def keychain
        @keychain ||= MoneyTree::Node.from_serialized_address(@pubkey)
      end

      # This is a callback method called from each order
      # whenever an order status changes.
      def order_status_changed(order)
        @order_callbacks.each do |c|
          c.call(order)
        end
      end

      private
        
        # Calls the block with each blockchain adapter until one of them does not fail.
        # Fails with the last exception.
        def try_blockchain_adapters(&block)
          last_exception = nil
          @blockchain_adapters.each do |adapter|
            begin
              result = yield(adapter)
              last_exception = nil
              return result
            rescue Exception => e
              last_exception = e
              # If an Exception is raised, it passes on
              # to the next adapter and attempts to call a method on it.
            end
          end
          raise last_exception if last_exception
        end

    end



  end

  class Gateway

    include GatewayModule

    def initialize
      @blockchain_adapters   = [Blockchain::BlockchainInfoAdapter.mainnet_adapter, Blockchain::HelloblockIoAdapter.mainnet_adapter]
      @status_check_schedule = DEFAULT_STATUS_CHECK_SCHEDULE
    end

    def order_class
      "Straight::Order"
    end

  end

end
