module Straight

  class Gateway

    # Determines the algorithm for consequitive checks of the order status.
    DEFAULT_STATUS_CHECK_SCHEDULE = -> (period, iteration_index) do
      return false if period > 640
      iteration_index += 1
      if iteration_index > 5
        period          *= 2
        iteration_index  = 0
      end
      return { period: period, iteration_index: iteration_index }
    end

    DEFAULT_BLOCKCHAIN_ADAPTERS = [BlockchainAdapter::BlockchainInfo, BlockchainAdapter::HelloblockIo]

    attr_reader :status_check_schedule

    def initialize(
      pubkey:,
      next_address_index:     0,
      confirmations_required: 0,
      status_check_schedule:  DEFAULT_STATUS_CHECK_SCHEDULE,
      blockchain_adapters:    DEFAULT_BLOCKCHAIN_ADAPTERS
    )

      @pubkey                 = pubkey
      @next_address_index     = next_address_index
      @confirmations_required = confirmations_required
      @status_check_schedule  = status_check_schedule
      @blockchain_adapters    = blockchain_adapters

    end

    def method_missing(method_name, *args)
      if [:fetch_transaction, :fetch_transactions_for, :fetch_balance_for].include?(method_name)
        call_blockchain_adapter_method(method_name, *args)
      else
        raise NoMethodError, message: "No such method ##{method} for #{self.class.to_s}"
      end
    end

    private

      def call_blockchain_adapter_method(method_name, *args)
        exception = nil
        @blockchain_adapters.each do |a|
          begin
            result = a.send(method_name, *args)
            exception = nil
            return result
          rescue Exception => e
            exception = e
            # If an Exception is raised, it passes on
            # to the next adapter and attempts to call a method on it.
          end
        end
        raise exception if exception
      end

  end

end
