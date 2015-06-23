module Straight
  module Blockchain

    class MyceliumAdapter < Adapter

      def self.mainnet_adapter
        instance = self.instance
        instance._initialize("https://mws2.mycelium.com/wapi/wapi")
        instance
      end
      
      def self.testnet_adapter
        instance = self.instance
        instance._initialize("https://node3.mycelium.com/wapitestnet/wapi")
        instance
      end
      
      def _initialize(base_url)
        @latest_block = { cache_timestamp: nil, block: nil }
        @base_url = base_url
      end

      # Returns transaction info for the tid
      def fetch_transaction(tid, address: nil)
        transaction = api_request('getTransactions', { txIds: [tid] })['transactions'].first
        straighten_transaction transaction, address: address
      end

      # Supposed to returns all transactions for the address, but
      # currently actually returns the first one, since we only need one.
      def fetch_transactions_for(address)
        tid = api_request('queryTransactionInventory', { addresses: [address], limit: 1 })["txIds"].first
        tid ? [fetch_transaction(tid, address: address)] : []
      end

      # Returns the current balance of the address
      def fetch_balance_for(address)
        unspent = 0
        api_request('queryUnspentOutputs', { addresses: [address]})['unspent'].each do |out|
          unspent += out['value']
        end
        unspent
      end

      def latest_block(force_reload: false)
        # If we checked Blockchain.info latest block data
        # more than a minute ago, check again. Otherwise, use cached version.
        if @latest_block[:cache_timestamp].nil?              ||
           @latest_block[:cache_timestamp] < (Time.now - 60) ||
           force_reload
          @latest_block = {
            cache_timestamp: Time.now,
            block: api_request('queryUnspentOutputs', { addresses: []} )
          }
        else
          @latest_block
        end
      end

      private

        def api_request(method, params={})
          begin
            JSON.parse(HTTParty.post(
              "#{@base_url}/#{method}",
              body: params.merge({version: 1}).to_json,
              headers: { 'Content-Type' => 'application/json' },
              timeout: 15,
              verify: false
            ).body || '')['r']
          rescue HTTParty::Error => e
            raise RequestError, YAML::dump(e)
          rescue JSON::ParserError => e
            raise RequestError, YAML::dump(e)
          end
        end

        # Converts transaction info received from the source into the
        # unified format expected by users of BlockchainAdapter instances.
        def straighten_transaction(transaction, address: nil)

          # Get the block number this transaction was included into
          block_height = transaction['height']
          tid          = transaction['txid']

          # Converting from Base64 to binary
          transaction = transaction['binary'].unpack('m0')[0]

          # Decoding
          transaction = BTC::Transaction.new(data: transaction)

          outs         = []
          total_amount = 0

          transaction.outputs.each do |out|
            amount = out.value
            receiving_address = out.script.standard_address
            total_amount += amount if address.nil? || address == receiving_address
            outs << {amount: amount, receiving_address: receiving_address}
          end

          {
            tid:           tid,
            total_amount:  total_amount.to_i,
            confirmations: calculate_confirmations(block_height),
            outs:          outs
          }
        end

        # When we call #calculate_confirmations, it doesn't always make a new
        # request to the blockchain API. Instead, it checks if cached_id matches the one in
        # the hash. It's useful when we want to calculate confirmations for all transactions for
        # a certain address without making any new requests to the Blockchain API.
        def calculate_confirmations(block_height, force_latest_block_reload: false)

          if block_height && block_height != -1
            latest_block(force_reload: force_latest_block_reload)[:block]["height"] - block_height + 1
          else
            0
          end

        end

    end

  end
end
