module Straight
  class HelloblockIoAdapter < BlockchainAdapter
    
    def self.mainnet_adapter
      self.new("https://mainnet.helloblock.io/v1")
    end
    
    def self.testnet_adapter
      raise "Not Supported Yet"
    end
    
    def initializa(base_url)
      @base_url = base_url
    end
    
    # Returns transaction info for the tid
    def fetch_transaction(tid)
      straighten_transaction JSON.parse(http_request("#{@base_url}/transactions/#{tid}"))['data']['transaction']
    end

    # Returns all transactions for the address
    def fetch_transactions_for(address)
      address      = JSON.parse(http_request("#{@base_url}/addresses/#{address}/transactions"))['data']
      transactions = address['transactions']
      transactions.map { |t| straighten_transaction(t) }
    end

    # Returns the current balance of the address
    def fetch_balance_for(address)
      JSON.parse(http_request("#{@base_url}/addresses/#{address}"))['data']['address']['balance']
    end

    private

      # Converts transaction info received from the source into the
      # unified format expected by users of BlockchainAdapter instances.
      def straighten_transaction(transaction)
        outs = transaction['outputs'].map do |out| 
          { amount: out['value'], receiving_address: out['address'] }
        end
        {
          total_amount:  transaction['totalOutputsValue'],
          confirmations: transaction['confirmations'],
          outs:          outs
        }
      end

  end
end
