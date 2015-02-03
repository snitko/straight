module Straight
  module ExchangeRate

    class AverageRateAdapter < Adapter

      # Takes exchange rate adapters instances or classes as an arguments
      def initialize(*adapters)
        @adapters = adapters.map{ |adapter| adapter.respond_to?(:new) ? adapter.new : adapter }
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

    end

  end
end