module StraightEngine
  module BlockchainAdapter

    # An almost abstract class, providing guidance for the interfaces of
    # all blockchain adapters as well as supplying some useful methods.
    class BlockchainInfo < Base

      require 'net/http'
      require 'uri'

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
            { total_amount: total_amount, outs: outs }
          end

      end

    end

  end
end
