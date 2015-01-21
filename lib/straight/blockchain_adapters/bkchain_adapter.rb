# https://bkchain.org/bitcoin/api/v1/address/balance/3B1QZ8FpAaHBgkSB5gFt76ag5AW9VeP8xp
# JSON.parse(http_request("https://bkchain.org/bitcoin/api/v1/address/balance/#{address}"))

module Straight
  module Blockchain

    class BkchainAdapter < Adapter

      def self.mainnet_adapter
        self.new("https://bkchain.org/bitcoin/api/v1")
      end
      
      def self.testnet_adapter
        raise "Not Supported Yet"
      end
      
      def initialize(base_url)
        @base_url = base_url
      end

      # Returns transaction info for the tid
      def fetch_transaction(tid, address: nil)
        straighten_transaction JSON.parse(http_request("#{@base_url}/tx/hash/#{tid}"), address: address)
      end

      # Returns all transactions for the address
      def fetch_transactions_for(address)
        debugger
        # transactions = JSON.parse(http_request("#{@base_url}/tx/hash/#{tid}"))['txs']
        transactions.map { |t| straighten_transaction(t, address: address) }
      end

      # Returns the current balance of the address
      def fetch_balance_for(address)
        debugger
        JSON.parse(http_request("#{@base_url}/address/balance/#{address}?confirmations=3"))[0]["balance"].to_i
      end

      private

        # Converts transaction info received from the source into the
        # unified format expected by users of BlockchainAdapter instances.
        def straighten_transaction(transaction, address: nil)
          outs         = []
          total_amount = 0
          transaction['outs'].each do |out|
            total_amount += out['v'] if address.nil? || address == out['addr']
            outs << { amount: out['v'], receiving_address: out['addr'] }
          end
          # total_amount = transaction['out'] if address.nil? || address == transaction['addr']
          # outs << { amount: total_amount, receiving_address: transaction['addr'] }

          {
            tid:           transaction['hash'],
            total_amount:  total_amount,
            confirmations: transaction['confirmations'],
            outs:          outs
          }
        end

    end

  end
end
