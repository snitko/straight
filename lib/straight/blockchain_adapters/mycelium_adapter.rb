module Straight
  module Blockchain

    class MyceliumAdapter < Adapter

      MAINNET_SERVERS = ["https://mws6.mycelium.com/wapi/wapi",
                         "https://mws7.mycelium.com/wapi/wapi",
                         "https://mws2.mycelium.com/wapi/wapi"]
      TESTNET_SERVERS = ["https://node3.mycelium.com/wapitestnet/wapi"]

      def self.mainnet_adapter
        instance = new
        instance._initialize(MAINNET_SERVERS)
        instance
      end
      
      def self.testnet_adapter
        instance = new
        instance._initialize(TESTNET_SERVERS)
        instance
      end
      
      def _initialize(servers)
        @latest_block = { cache_timestamp: nil, block: nil }
        @api_servers = servers
        set_base_url
      end

      # Set url for API request.
      # @param num [Integer] a number of server in array
      def set_base_url(num = 0)
        return nil if num >= @api_servers.size
        @base_url = @api_servers[num]
      end

      def next_server
        set_base_url(@api_servers.index(@base_url) + 1)
      end

      # Returns transaction info for the tid
      def fetch_transaction(tid, address: nil)
        transaction = api_request('getTransactions', { txIds: [tid] })['transactions'].first
        straighten_transaction transaction, address: address
      end

      # Supposed to returns all transactions for the address, but
      # currently actually returns the first one, since we only need one.
      def fetch_transactions_for(address)
        # API may return nil instead of an empty array if address turns out to be invalid
        # (for example when trying to supply a testnet address instead of mainnet while using
        # mainnet adapter.
        if api_response = api_request('queryTransactionInventory', { addresses: [address], limit: 1 })
          tid = api_response["txIds"].first
          tid ? [fetch_transaction(tid, address: address)] : []
        else
          raise BitcoinAddressInvalid, message: "address in question: #{address}"
        end
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
          attempts = 0
          begin
            attempts += 1
            JSON.parse(HTTParty.post(
              "#{@base_url}/#{method}",
              body: params.merge({version: 1}).to_json,
              headers: { 'Content-Type' => 'application/json' },
              timeout: 15,
              verify: false
            ).body || '')['r']
          rescue HTTParty::Error => e
            retry if next_server
            raise RequestError, YAML::dump(e)
          rescue JSON::ParserError => e
            raise RequestError, YAML::dump(e)
          rescue Net::ReadTimeout
            raise HTTParty::Error if attempts >= MAX_TRIES
            sleep 0.5
            retry
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
            total_amount += amount if address.nil? || address == receiving_address.to_s
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
