module StraightEngine
  class BlockchainAdapter

    # An almost abstract class, providing guidance for the interfaces of
    # all blockchain adapters as well as supplying some useful methods.
    class Base
      require 'json'
      require 'uri'
      require 'open-uri'
      require 'yaml'

      class << self

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
            raise "abstract method #straighten_transaction, please reload it in #{self.to_s}"
          end

      end

    end

  end
end
