module Straight
  module ExchangeRate

    class BitstampAdapter < Adapter
      
      FETCH_URL = 'https://www.bitstamp.net/api/ticker/'

      def rate_for(currency_code)
        super
        raise CurrencyNotSupported if currency_code != 'USD'
        rate = get_rate_value_from_hash(@rates, "last")
        rate_to_f(rate)
      end

    end

  end
end
