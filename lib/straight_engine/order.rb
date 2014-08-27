module StraightEngine

  # Instances of this class are generated when we'd like to start watching
  # some addresses to check whether a transaction containing a certain amount
  # has arrived to it.
  #
  # It is worth noting that instances do not know how store themselves anywhere,
  # so as the class is written here, those instances are only supposed to exist
  # in memory. Storing orders is entirely up to you.
  class Order

    # Third-Party services or the local blockchain copy
    # represented by wrapper classes that make all the necessary queries
    # to check certain addresses or transactions.
    DEFAULT_BLOCKCHAIN_ADAPTERS = []
    
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

    STATUSES = {
      new:          0, # no transactions received
      unconfirmed:  1, # transaction has been received doesn't have enough confirmations yet
      paid:         2, # transaction received with enough confirmations and the correct amount
      underpaid:    3, # amount that was received in a transaction was not enough
      overpaid:     4  # amount that was received in a transaction was too large
    }

    class IncorrectAmount < Exception; end

    # Extended public key according to BIP32 from which addresses will be
    # derived deterministically and sequentially. Current sequence number,
    # however, is determined by the #next_address_counter property set when an object
    # is created. We do not store neither pubkey, nor the incrementer number anywhere.
    attr_reader :pubkey

    # Amount is always an Integer, in satoshis
    attr_reader :amount

    # This should contain a lambda to be called whenever the status changes
    attr_accessor :status_callback

    attr_writer :address
    
    def initialize(
      amount:,
      pubkey:,
      next_address_index:     0,
      confirmations_required: 0,
      blockchain_adapters:    DEFAULT_BLOCKCHAIN_ADAPTERS,
      status_check_schedule:  DEFAULT_STATUS_CHECK_SCHEDULE
    )
      @pubkey                 = pubkey
      @next_address_index     = next_address_index
      @confirmations_required = confirmations_required
      @created_at             = Time.now
      @blockchain_adapters    = blockchain_adapters
      @status_check_schedule  = status_check_schedule

      raise Order::IncorrectAmount if amount.nil? || !amount.kind_of?(Integer) || amount <= 0
      @amount = amount # In satoshis

    end

    # Returns a Base58-encoded Bitcoin address to which the payment transaction
    # is expected to arrive.
    def address
      @address ||= 'new address' # TODO: actually generate an address
    end

    # Returns an array of transactions for the order's address, each as a hash:
    #   [ {"txid": "feba9e7bfea...", "amount": 1202000, ...} ]
    #
    # An order is supposed to have only one transaction to its address, but we cannot
    # always guarantee that (especially when a merchant decides to reuse the address
    # for some reason -- he shouldn't but you know people).
    #
    # Therefore, this method returns all of the transactions.
    # For compliance, there's also a #transaction method which always returns
    # the last transaction made to the address.
    def transactions(reload: false)
      #reload || !@@transactions ? @@transactions = adapter
    end

    # Last transaction made to the address. Always use this method to check whether a transaction
    # for this order has arrived. We pick last and not first because an address may be reused and we
    # always assume it's the last transaction that we want to check.
    def transaction(reload: false)
      # if reload true
        # asks one of the (or all) @blockchain_adapters to reload info about the transaction with that id
    end

    # Checks #transaction and returns one of the STATUSES based
    # on the meaning of each status and the contents of transaction
    # If as_string is set to true, then each status is returned as Symbol, otherwise
    # an equivalent Integer from STATUSES is returned.
    def status(as_sym: false, reload: false)
    end
    
    def status=(s)
      @status = s
      # invoke a callback from @status_callback if it's not nil
    end

    # Starts a loop which calls #status(reload: true) according to the schedule
    # determined in @status_check_schedule. This method is supposed to be
    # called in a separate thread, for example:
    #
    #   Thread.new do
    #     order.start_periodic_status_check
    #   end
    #
    def start_periodic_status_check
      check_status_on_schedule
    end
    
    def check_status_on_schedule(period: 10, iteration_index: 0)
      self.status(reload: true)
      schedule = @status_check_schedule.call(period, iteration_index)
      if schedule
        sleep period
        check_status_on_schedule(
          period:          schedule[:period],
          iteration_index: schedule[:iteration_index]
        )
      end
    end

  end

end
