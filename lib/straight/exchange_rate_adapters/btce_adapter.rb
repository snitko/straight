module Straight
  module ExchangeRate

    class BtceAdapter < Adapter
      
      FETCH_URL = 'https://btc-e.com/api/2/btc_usd/ticker'

      def rate_for(currency_code)
        super
        raise CurrencyNotSupported if !FETCH_URL.include?("btc_#{currency_code.downcase}")
        rate_to_f(@rates['ticker']['last'])
      end

    end

  end
end