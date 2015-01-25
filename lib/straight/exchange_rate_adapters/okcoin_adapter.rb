module Straight
  module ExchangeRate

    class OkcoinAdapter < Adapter
      
      FETCH_URL = 'https://www.okcoin.com/api/ticker.do?ok=1'

      def rate_for(currency_code)
        super
        raise CurrencyNotSupported if currency_code != 'USD'
        @rates['ticker']['last'].to_f
      end

    end

  end
end