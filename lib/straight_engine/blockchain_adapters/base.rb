module StraightEngine
  module BlockchainAdapter

    # An almost abstract class, providing guidance for the interfaces of
    # all blockchain adapters as well as supplying some useful methods.
    class Base

      require 'json'

      # Returns transaction info for the tid
      def fetch_transaction(tid)
      end

      # Returns all transactions for the address
      def fetch_transactions_for(address)
      end

      private

        # Converts transaction info received from the source into the
        # unified format expected by users of BlockchainAdapter instances.
        def straighten_transaction(transaction)
        end

    end

  end
end
