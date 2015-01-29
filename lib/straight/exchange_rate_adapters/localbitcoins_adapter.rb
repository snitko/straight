module Straight
  module ExchangeRate

    class LocalbitcoinsAdapter < Adapter
      
      FETCH_URL = 'https://localbitcoins.com/bitcoinaverage/ticker-all-currencies/'

      def rate_for(currency_code)
        super
        rate = get_rate_value_from_hash(@rates, currency_code.upcase, 'rates', 'last')
        rate ? rate_to_f(rate) : raise(CurrencyNotSupported)
      end

    end

  end
end