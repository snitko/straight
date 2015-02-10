module Straight
  module ExchangeRate

    class AverageRateAdapter < Adapter

      # Takes exchange rate adapters instances or classes as arguments
      def initialize(*adapters)
        @adapters = adapters.map{ |adapter| adapter.respond_to?(:new) ? adapter.new : adapter }
      end

      def fetch_rates!
        @adapters.each do |adapter|
          adapter.fetch_rates!
        end
      end

      def rate_for(currency_code)
        rates = []
        @adapters.each do |adapter| 
          begin
            rates << adapter.rate_for(currency_code)
          rescue CurrencyNotSupported
            rates << nil
          end
        end

        unless rates.select(&:nil?).size == @adapters.size 
          rates.compact!
          rates.inject {|sum, rate| sum + rate} / rates.size
        else
          raise CurrencyNotSupported
        end
      end

      def get_rate_value_from_hash(rates_hash, *keys)
        raise "This method is not supposed to be used in #{self.class}."
      end

      def rate_to_f(rate)
        raise "This method is not supposed to be used in #{self.class}."
      end

    end

  end
end