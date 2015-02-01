module Straight
  module ExchangeRate

    class KrakenAdapter < Adapter
      
      FETCH_URL = 'https://api.kraken.com/0/public/Ticker?pair=xbtusd'

      def rate_for(currency_code)
        super
        rate = get_rate_value_from_hash(@rates, 'result', 'XXBTZ' + currency_code.upcase, 'c')
        rate = rate.kind_of?(Array) ? rate.first : raise(CurrencyNotSupported)
        rate_to_f(rate)
      end

    end

  end
end