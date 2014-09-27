module Straight
  # A base class, providing guidance for the interfaces of
  # all blockchain adapters as well as supplying some useful methods.
  class BlockchainAdapter

    # Raised when blockchain data cannot be retrived for any reason.
    # We're not really intereste in the precise reason, although it is
    # stored in the message.
    class RequestError < Exception; end

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
        raise "Please implement #straighten_transaction in #{self.to_s}"
      end

  end
end
