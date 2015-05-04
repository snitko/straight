module Straight

  module Blockchain
    # A base class, providing guidance for the interfaces of
    # all blockchain adapters as well as supplying some useful methods.
    class Adapter

      require 'singleton'
      include Singleton

      # Raised when blockchain data cannot be retrived for any reason.
      # We're not really intereste in the precise reason, although it is
      # stored in the message.
      class RequestError < Exception; end

      def fetch_transaction(tid)
        raise "Please implement #fetch_transaction in #{self.to_s}"
      end

      def fetch_transactions_for(address)
        raise "Please implement #fetch_transactions_for in #{self.to_s}"
      end

      def fetch_balance_for(address)
        raise "Please implement #fetch_balance_for in #{self.to_s}"
      end

      private

        # Converts transaction info received from the source into the
        # unified format expected by users of BlockchainAdapter instances.
        def straighten_transaction(transaction)
          raise "Please implement #straighten_transaction in #{self.to_s}"
        end

    end

  end
end
