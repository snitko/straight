module Straight
  module ExchangeRate

    class LocalbitcoinsAdapter < Adapter
      
      FETCH_URL = 'https://localbitcoins.com/bitcoinaverage/ticker-all-currencies/'

      def rate_for(currency_code)
        super
        if rate = @rates[currency_code.upcase]
          rate_to_f(rate['rates']['last'])
        else
          raise CurrencyNotSupported
        end
      end

    end

  end
end