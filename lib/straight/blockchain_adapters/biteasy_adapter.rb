module Straight
  module Blockchain

    class BiteasyAdapter < Adapter

      def self.mainnet_adapter
        self.new("https://api.biteasy.com/blockchain/v1")
      end
      
      def self.testnet_adapter
        raise "Not Supported Yet"
      end
      
      def initialize(base_url)
        @base_url = base_url
      end

      # Returns the current balance of the address
      def fetch_balance_for(address)
        # I would like to check if address in returning hash matches our address in passed params
        # seems like it will be safer
        JSON.parse(http_request("#{@base_url}/addresses/#{address}"))['data']['balance']
      end

    end

  end

end