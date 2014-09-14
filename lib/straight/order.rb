module Straight

  # Instances of this class are generated when we'd like to start watching
  # some addresses to check whether a transaction containing a certain amount
  # has arrived to it.
  #
  # It is worth noting that instances do not know how store themselves anywhere,
  # so as the class is written here, those instances are only supposed to exist
  # in memory. Storing orders is entirely up to you.
  class Order

    # Worth noting that statuses above 1 are immutable. That is, an order status cannot be changed
    # if it is more than 1. It makes sense because if an order is paid (5) or expired (2), nothing
    # else should be able to change the status back. Similarly, if an order is overpaid (4) or
    # underpaid (5), it requires admin supervision and possibly a new order to be created.
    STATUSES = {
      new:          0, # no transactions received
      unconfirmed:  1, # transaction has been received doesn't have enough confirmations yet
      paid:         2, # transaction received with enough confirmations and the correct amount
      underpaid:    3, # amount that was received in a transaction was not enough
      overpaid:     4, # amount that was received in a transaction was too large
      expired:      5  # too much time passed since creating an order
    }

    class IncorrectAmount < Exception; end

    attr_reader   :amount  # Amount is always an Integer, in satoshis
    attr_accessor :address # An address to which the payment is supposed to be sent
    
    def initialize(amount:, gateway:, address:, keychain_id:)
      @created_at         = Time.now
      @gateway            = gateway
      @address            = address
      @keychain_id        = keychain_id
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
      
      # Prohibit status update if the order was paid in some way.
      # This is just a caching workaround so we don't query
      # the blockchain needlessly. The actual safety switch is in the setter.
      # Therefore, even if you remove the following line, status won't actually
      # be allowed to change.
      return @status if @status && @status > 1 

      if reload || !@status
        t = transaction(reload: reload)
        self.status = if t.nil?
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

    def status=(new_status)
      # Prohibit status update if the order was paid in some way,
      # so statuses above 1 are in fact immutable.
      return false if @status && @status > 1 
      
      @gateway.order_status_changed(self) unless @status == new_status
      @status = new_status
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
      if schedule && self.status < 2 # Stop checking if status is >= 2
        sleep period
        check_status_on_schedule(
          period:          schedule[:period],
          iteration_index: schedule[:iteration_index]
        )
      else
        self.status = STATUSES[:expired]
      end
    end

  end

end
