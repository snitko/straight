module Straight
  module ExchangeRate

    class BitpayAdapter < Adapter
      
      FETCH_URL = 'https://bitpay.com/api/rates'

      def rate_for(currency_code)
        super
        @rates.each do |rt|
          if rt['code'] == currency_code
            rate = get_rate_value_from_hash(rt, 'rate')
            return rate_to_f(rate)
          end
        end
        raise CurrencyNotSupported 
      end

    end

  end
end
