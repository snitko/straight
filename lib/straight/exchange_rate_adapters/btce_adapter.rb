module Straight
  module ExchangeRate

    class BtceAdapter < Adapter
      
      FETCH_URL = 'https://btc-e.com/api/2/btc_usd/ticker'

      def rate_for(currency_code)
        super
        raise CurrencyNotSupported if !FETCH_URL.include?("btc_#{currency_code.downcase}")
        if @rates['ticker']['last'] 
          @rates['ticker']['last'].to_f 
        else
          raise "cant find rate, api might have changed"
        end
      end

    end

  end
end