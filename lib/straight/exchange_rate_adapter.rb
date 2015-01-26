module Straight
  module ExchangeRate

    class Adapter

      class CurrencyNotFound     < Exception; end
      class FetchingFailed       < Exception; end
      class CurrencyNotSupported < Exception; end
      class NilValueNotAllowed   < Exception; end

      def initialize(rates_expire_in: 1800)
        @rates_expire_in = rates_expire_in # in seconds
      end

      def convert_from_currency(amount_in_currency, btc_denomination: :satoshi, currency: 'USD')
        btc_amount = amount_in_currency.to_f/rate_for(currency)
        Satoshi.new(btc_amount, from_unit: :btc, to_unit: btc_denomination).to_unit
      end

      def convert_to_currency(amount, btc_denomination: :satoshi, currency: 'USD')
        amount_in_btc = Satoshi.new(amount.to_f, from_unit: btc_denomination).to_btc
        amount_in_btc*rate_for(currency)
      end

      def fetch_rates!
        raise "FETCH_URL is not defined!" unless self.class::FETCH_URL
        uri = URI.parse(self.class::FETCH_URL)
        begin
          @rates            = JSON.parse(uri.read(read_timeout: 4))
          @rates_updated_at = Time.now
        rescue OpenURI::HTTPError => e
          raise FetchingFailed
        end
      end

      def rate_for(currency_code)
        if !@rates_updated_at || (Time.now - @rates_updated_at) > @rates_expire_in
          fetch_rates!
        end
        nil # this should be changed in descendant classes
      end

      # this method will be used in #rate_for method in child classes, and will be checking that 
      # rate value != nil
      def rate_to_f(rate)
        rate ? rate.to_f : raise(NilValueNotAllowed)
      end

    end

  end
end
