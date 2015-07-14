module Straight
  module Blockchain
    
    class InsightAdapter < Adapter

      @@test_url = nil

      def self.mainnet_adapter(main_url:, test_url: nil)
        @@test_url = test_url
        new(main_url)
      end

      def self.testnet_adapter
        raise "Testnet not implemented" unless @@test_url
        new(@@test_url)
      end

      def initialize(host_url)
        @base_url = host_url
      end

      def fetch_transaction(tid, address: nil)
        res = api_request("/tx/", tid)
        straighten_transaction(res, address: address)
      end

      def fetch_transactions_for(address)
        res = api_request("/addr/", address)
        return [] if res["transactions"].empty?
        [fetch_transaction(res["transactions"].first, address: address)]
      end

      def fetch_balance_for(address)
        res = api_request("/addr/", address)
        res["balanceSat"].to_i
      end

    private

      def api_request(place, val)
        req_url = @base_url + place + val
        res = HTTParty.get(
          req_url,
          body: { 'Content-Type' => 'application/json' },
          timeout: 15,
          verify: false
        ).body
        JSON.parse(res)
      rescue HTTParty::Error => e
        raise RequestError, YAML::dump(e)
      rescue JSON::ParserError => e
        raise BitcoinAddressInvalid, message: "address in question: #{val}" if e.message.include?("Invalid address")
        raise RequestError, YAML::dump(e)
      end

      def straighten_transaction(transaction, address: nil)
        total_amount = 0
        tid = transaction["txid"]
        transaction["vout"].each do |o|
          total_amount += Satoshi.new(o["value"]) if address.nil? || address == o["scriptPubKey"]["addresses"].first
        end
        confirmations = transaction["confirmations"] 
        outs = transaction["vout"].map { |o| {amount: Satoshi.new(o["value"]).to_i, receiving_address: o["scriptPubKey"]["addresses"].first} }

        {
          tid:           tid,
          total_amount:  total_amount,
          confirmations: confirmations || 0,
          outs:          outs || []
        }
      end

    end

  end
end
