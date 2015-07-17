module Straight
  module Blockchain

    class BlockchainInfoAdapter < Adapter

      def self.mainnet_adapter
        instance = self.instance
        instance._initialize("https://blockchain.info")
        instance
      end
      
      def self.testnet_adapter
        raise "Not Supported Yet"
      end
      
      def _initialize(base_url)
        @latest_block = { cache_timestamp: nil, block: nil }
        @base_url = base_url
      end

      # Returns transaction info for the tid
      def fetch_transaction(tid, address: nil)
        straighten_transaction(api_request("/rawtx/#{tid}"), address: address)
      end

      # Returns all transactions for the address
      def fetch_transactions_for(address)
        transactions = api_request("/rawaddr/#{address}")['txs']
        transactions.map { |t| straighten_transaction(t, address: address) }
      end

      # Returns the current balance of the address
      def fetch_balance_for(address)
        api_request("/rawaddr/#{address}")['final_balance']
      end

      def latest_block(force_reload: false)
        # If we checked Blockchain.info latest block data
        # more than a minute ago, check again. Otherwise, use cached version.
        if @latest_block[:cache_timestamp].nil?              ||
           @latest_block[:cache_timestamp] < (Time.now - 60) ||
           force_reload
          @latest_block = {
            cache_timestamp: Time.now,
            block: api_request("/latestblock")
          }
        else
          @latest_block
        end
      end

      private

        def api_request(url)
          conn = Faraday.new(url: "#{@base_url}/#{url}", ssl: { verify: false }) do |faraday|
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
          transaction['out'].each do |out|
            total_amount += out['value'] if address.nil? || address == out['addr']
            outs << { amount: out['value'], receiving_address: out['addr'] }
          end

          {
            tid:           transaction['hash'],
            total_amount:  total_amount,
            confirmations: calculate_confirmations(transaction),
            outs:          outs
          }
        end


        # When we call #calculate_confirmations, it doesn't always make a new
        # request to the blockchain API. Instead, it checks if cached_id matches the one in
        # the hash. It's useful when we want to calculate confirmations for all transactions for
        # a certain address without making any new requests to the Blockchain API.
        def calculate_confirmations(transaction, force_latest_block_reload: false)

          if transaction["block_height"]
            latest_block(force_reload: force_latest_block_reload)[:block]["height"] - transaction["block_height"] + 1
          else
            0
          end

        end

    end

  end
end
