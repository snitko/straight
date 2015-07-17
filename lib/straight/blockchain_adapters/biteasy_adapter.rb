module Straight
  module Blockchain

    class BiteasyAdapter < Adapter

      def self.mainnet_adapter
        instance = self.instance
        instance._initialize("https://api.biteasy.com/blockchain/v1")
        instance
      end
      
      def self.testnet_adapter
        raise "Not Supported Yet"
      end
      
      def _initialize(base_url)
        @base_url = base_url
      end

      # Returns the current balance of the address
      def fetch_balance_for(address)
        api_request("/addresses/#{address}")['data']['balance']
      end

      # Returns transaction info for the tid
      def fetch_transaction(tid, address: nil)
        straighten_transaction api_request("/transactions/#{tid}"), address: address
      end

      # Returns all transactions for the address
      def fetch_transactions_for(address)
        transactions = api_request("/transactions?address=#{address}")['data']['transactions']
        transactions.map { |t| straighten_transaction(t, address: address) }
      end

      private

        def api_request(url)
          conn = Faraday.new("#{@base_url}/#{url}", ssl: { verify: false }) do |faraday|
            faraday.adapter Faraday.default_adapter
          end
          result = conn.get
          unless result.status == 200
            raise RequestError, "Cannot access remote API, response code was #{result.code}"
          end
          JSON.parse(result.body)
        rescue JSON::ParserError => e
          raise RequestError, YAML::dump(e)
        rescue Exception => e
          raise RequestError, YAML::dump(e)
        end

        # Converts transaction info received from the source into the
        # unified format expected by users of BlockchainAdapter instances.
        def straighten_transaction(transaction, address: nil)
          outs         = []
          total_amount = 0
          transaction['data']['outputs'].each do |out|
            total_amount += out['value'] if address.nil? || address == out['to_address']
            outs << { amount: out['value'], receiving_address: out['to_address'] } 
          end

          {
            tid:           transaction['data']['hash'],
            total_amount:  total_amount,
            confirmations: transaction['data']['confirmations'],
            outs:          outs
          }
        end

    end

  end

end
