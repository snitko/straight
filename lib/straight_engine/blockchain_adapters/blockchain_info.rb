module StraightEngine
  module BlockchainAdapter

    # An almost abstract class, providing guidance for the interfaces of
    # all blockchain adapters as well as supplying some useful methods.
    class BlockchainInfo < Base

      require 'net/http'
      require 'uri'

      # When we call calculate_confirmations, it doesn't always make a new
      # request to the blockchain API. Instead, it checks if cached_id matches the one in
      # the hash. It's useful when we want to calculate confirmations for all transactions for
      # a certain address without making any new requests to the Blockchain API.
      @@latest_block = { cache_timestamp: nil, block: nil }

      API_BASE_URL = "http://blockchain.info"

      class << self
      
        # Returns transaction info for the tid
        def fetch_transaction(tid)
          straighten_transaction JSON.parse(Net::HTTP.get(URI.parse("#{API_BASE_URL}/rawtx/#{tid}")))
        end

        # Returns all transactions for the address
        def fetch_transactions_for(address)
          address      = JSON.parse(Net::HTTP.get(URI.parse("#{API_BASE_URL}/rawaddr/#{address}")))
          transactions = address['txs']
          transactions.map! { |t| straighten_transaction(t) }
          { balance: address['final_balance'] , transactions: transactions }
        end

        private

          # Converts transaction info received from the source into the
          # unified format expected by users of BlockchainAdapter instances.
          def straighten_transaction(transaction)
            outs         = []
            total_amount = 0
            transaction['out'].each do |out| 
              total_amount += out['value']
              outs << { amount: out['value'], receiving_address: out['addr'] }
            end

            {
              total_amount:  total_amount,
              confirmations: calculate_confirmations(transaction),
              outs:          outs
            }
          end

          def calculate_confirmations(transaction, force_latest_block_reload: false)

            # If we checked Blockchain.info latest block data
            # more than a minute ago, check again. Otherwise, use cached version.
            if @@latest_block[:cache_timestamp].nil?              ||
               @@latest_block[:cache_timestamp] < (Time.now - 60) ||
               force_latest_block_reload
              @@latest_block = {
                cache_timestamp: Time.now,
                block: JSON.parse(Net::HTTP.get(URI.parse("#{API_BASE_URL}/latestblock")))
              }
            end

            if transaction["block_height"]
              @@latest_block[:block]["height"] - transaction["block_height"] + 1
            else
              0
            end

          end

      end

    end

  end
end
