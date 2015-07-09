module Straight
  module Blockchain
    
    class InsightAdapter < Adapter

      def self.mainnet_adapter(host_url)
        new(host_url)
      end

      def initialize(host_url)
        @base_url = host_url
      end

      def fetch_transaction(tid)
        res = api_request("/tx/", tid)
        straighten_transaction(res)
      end

      def fetch_transactions_for(address)
        res = api_request("/addr/", address)
        raise BitcoinAddressInvalid, message: "address in question: #{address}" unless res
        return [] if res["transactions"].empty?
        [fetch_transaction(res["transactions"].first)]
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
        JSON.parse(res || "")
      rescue HTTParty::Error => e
        raise RequestError, YAML::dump(e)
      rescue JSON::ParserError => e
        raise RequestError, YAML::dump(e)
      end

      def straighten_transaction(transaction)
        tid = transaction["txid"]
        total_amount = transaction["valueOut"]
        confirmations = transaction["confirmations"] 
        outs = transaction["vout"].map { |o| {amount: Satoshi.new(o["value"]).to_i, receiving_address: o["scriptPubKey"]["addresses"].first} }

        {
          tid:           tid,
          total_amount:  Satoshi.new(total_amount).to_i,
          confirmations: confirmations || 0,
          outs:          outs || []
        }
      end

    end

  end
end
