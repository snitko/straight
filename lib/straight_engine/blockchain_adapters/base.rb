module StraightEngine
  class BlockchainAdapter

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
