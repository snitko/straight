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

    attr_reader :status_check_schedule, :orders

    # Extended public key according to BIP32 from which addresses will be
    # derived deterministically and sequentially. Current sequence number,
    # however, is determined by the #next_address_counter property set when an object
    # is created. We do not store neither pubkey, nor the incrementer number anywhere.
    attr_reader :pubkey

    def initialize(
      pubkey:,
      next_address_index:     1,
      confirmations_required: 0,
      status_check_schedule:  DEFAULT_STATUS_CHECK_SCHEDULE,
      blockchain_adapters:    nil,
      keep_orders_in_memory:  false
    )

      @pubkey                 = pubkey
      @next_address_index     = next_address_index
      @confirmations_required = confirmations_required
      @status_check_schedule  = status_check_schedule
      @blockchain_adapters    = blockchain_adapters || [BlockchainInfoAdapter.mainnet_adapter, HelloblockIoAdapter.mainnet_adapter]
      @keep_orders_in_memory  = keep_orders_in_memory

      @orders = []

    end

    def create_order(amount)
      order = Order.new(amount: amount, gateway: self, address: next_address)
      @orders << order if @keep_orders_in_memory
    end

    # Returns a Base58-encoded Bitcoin address to which the payment transaction
    # is expected to arrive.
    def next_address
      @next_address_index += 1
      @address ||= 'new address' # TODO: actually generate an address
    end
    
    # Fetches transaction from the first available adapter. If one adapter fails, tries another one.
    def fetch_transaction(tid)
      try_blockchain_adapters {|b| b.fetch_transaction(tid) }
    end
    
    def fetch_transactions_for(address)
      try_blockchain_adapters {|b| b.fetch_transactions_for(address) }
    end
    
    def fetch_balance_for(address)
      try_blockchain_adapters {|b| b.fetch_balance_for(address) }
    end

    private
      
      # Calls the block with each blockchain adapter until one of them does not fail.
      # Fails with the last exception.
      def try_blockchain_adapters(&block)
        last_exception = nil
        @blockchain_adapters.each do |adapter|
          begin
            result = yield(adapter)
            last_exception = nil
            return result
          rescue Exception => e
            last_exception = e
            # If an Exception is raised, it passes on
            # to the next adapter and attempts to call a method on it.
          end
        end
        raise last_exception if exception
      end

  end

end