module Straight
  module ExchangeRate

    class BitstampAdapter < Adapter
      
      FETCH_URL = 'https://www.bitstamp.net/api/ticker/'

      def rate_for(currency_code)
        super
        raise CurrencyNotSupported if currency_code != 'USD'
        @rates['last'].to_f
      end

    end

  end
end
