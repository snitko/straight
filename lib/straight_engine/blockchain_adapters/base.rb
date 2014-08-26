module StraightEngine
  module BlockchainAdapter

    # An almost abstract class, providing guidance for the interfaces of
    # all blockchain adapters as well as supplying some useful methods.
    
    # Raised when blockchain data cannot be retrived for any reason.
    # We're not really intereste in the precise reason, although it is
    # stored in the message.
    class RequestError < Exception; end

    class Base

      require 'json'
      require 'uri'
      require 'open-uri'
      require 'yaml'

      class << self

        # Returns transaction info for the tid
        def fetch_transaction(tid)
          raise "abstract method #fetch_transaction, please reload it in #{self.to_s}"
        end

        # Returns all transactions for the address
        def fetch_transactions_for(address)
          raise "abstract method #fetch_transactions_for, please reload it in #{self.to_s}"
        end

        # Returns the current balance of the address
        def fetch_balance_for(address)
          raise "abstract method #fetch_balance_for, please reload it in #{self.to_s}"
        end

        # This method is a wrapper for creating an HTTP request
        # to various services that ancestors of this class may use
        # to retrieve blockchain data. Why do we need a wrapper?
        # Because it respects timeouts.
        def http_request(url)
          uri = URI.parse(url)
          begin
            http = uri.read(read_timeout: 4)
          rescue OpenURI::HTTPError => e
            raise RequestError, YAML::dump(e)
          end
        end

      private

        # Converts transaction info received from the source into the
        # unified format expected by users of BlockchainAdapter instances.
        def straighten_transaction(transaction)
          raise "abstract method #straighten_transaction, please reload it in #{self.to_s}"
        end

      end

    end

  end
end
