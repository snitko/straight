module Straight
  module ExchangeRate

    class BitpayAdapter < Adapter
      
      FETCH_URL = 'https://bitpay.com/api/rates'

      def rate_for(currency_code)
        super
        @rates.each do |r|
          return r['rate'].to_f if r['code'] == currency_code
        end
        raise CurrencyNotSupported 
      end

    end

  end
end
