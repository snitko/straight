module Straight
  module ExchangeRate

    class Adapter

      class CurrencyNotFound < Exception; end

      def convert_from_currency(amount_in_currency, btc_denomination: :satoshi, currency: 'USD')
        btc_amount = amount_in_currency/rate_for(currency)
        Satoshi.new(btc_amount, from_unit: :btc, to_unit: btc_denomination).to_unit
      end

      def convert_to_currency(amount, btc_denomination: :satoshi, currency: 'USD')
        amount_in_btc = Satoshi.new(amount, from_unit: btc_denomination).to_btc
        amount_in_btc*rate_for(currency)
      end

      def rate_for(currency_code)
      end

    end

  end
end
