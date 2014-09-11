module Straight

  # Instances of this class are generated when we'd like to start watching
  # some addresses to check whether a transaction containing a certain amount
  # has arrived to it.
  #
  # It is worth noting that instances do not know how store themselves anywhere,
  # so as the class is written here, those instances are only supposed to exist
  # in memory. Storing orders is entirely up to you.
  class Order

    STATUSES = {
      new:          0, # no transactions received
      unconfirmed:  1, # transaction has been received doesn't have enough confirmations yet
      paid:         2, # transaction received with enough confirmations and the correct amount
      underpaid:    3, # amount that was received in a transaction was not enough
      overpaid:     4  # amount that was received in a transaction was too large
    }

    class IncorrectAmount < Exception; end

    attr_reader   :amount  # Amount is always an Integer, in satoshis
    attr_accessor :address # An address to which the payment is supposed to be sent
    
    def initialize(amount:, gateway:, address:)
      @created_at         = Time.now
      @gateway            = gateway
      @address            = address
      raise IncorrectAmount if amount.nil? || !amount.kind_of?(Integer) || amount <= 0
      @amount = amount # In satoshis
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
      @transactions = @gateway.fetch_transactions_for(address) if reload || !@transactions
      @transactions
    end

    # Last transaction made to the address. Always use this method to check whether a transaction
    # for this order has arrived. We pick last and not first because an address may be reused and we
    # always assume it's the last transaction that we want to check.
    def transaction(reload: false)
      transactions(reload: reload).first
    end

    # Checks #transaction and returns one of the STATUSES based
    # on the meaning of each status and the contents of transaction
    # If as_sym is set to true, then each status is returned as Symbol, otherwise
    # an equivalent Integer from STATUSES is returned.
    def status(as_sym: false, reload: false)
      if reload || !@status
        t = transaction(reload: reload)
        @status = if t.nil?
          STATUSES[:new]
        else
          if t[:confirmations] >= @gateway.confirmations_required
            if t[:total_amount] == amount
              STATUSES[:paid]
            elsif t[:total_amount] < amount
              STATUSES[:underpaid]
            else
              STATUSES[:overpaid]
            end
          else
            STATUSES[:unconfirmed]
          end
        end
      end
      as_sym ? STATUSES.invert[@status] : @status 
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
      schedule = @gateway.status_check_schedule.call(period, iteration_index)
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
