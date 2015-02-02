module Straight
  module ExchangeRate

    class AverageRateAdapter

      # Takes exchange rate adapters class names as an arguments
      def initialize(*adapter_names)
        @rates = []
        adapter_names.each do |adapter|
          @rates << adapter.rate_for('USD')
        end
      end

      def calculate_avg_rate
        @rates.compact!
        @rates.inject {|sum, rate| sum + rate} / @rates.size
      end

    end

  end
end