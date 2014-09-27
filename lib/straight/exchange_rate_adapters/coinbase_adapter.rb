module Straight
  module ExchangeRate

    class CoinbaseAdapter < Adapter
      
      FETCH_URL = 'https://coinbase.com/api/v1/currencies/exchange_rates'

      def rate_for(currency_code)
        super
        if rate = @rates["btc_to_#{currency_code.downcase}"]
          return rate.to_f
        end
        raise CurrencyNotSupported 
      end

    end

  end
end
