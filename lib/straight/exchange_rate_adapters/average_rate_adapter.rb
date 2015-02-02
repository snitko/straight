module Straight
  module ExchangeRate

    class AverageRateAdapter

      # Takes exchange rate adapters instances as an arguments
      def initialize(*adapter_instances)
        @rates = []
        adapter_instances.each do |adapter|
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