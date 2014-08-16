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
    SOURCES = []

    STATUSES = {
      new:  0,        # no transactions received
      unconfirmed: 1, # transaction has been received doesn't have enough confirmations yet
      paid: 2,        # transaction received with enough confirmations and the correct amount
      amount_not_enough: 3, # amount that was received in a transaction was not enough
      amount_too_large:  4  # amount that was received in a transaction was too large
    }

    class IncorrectAmount < Exception; end

    # Extended public key according to BIP32 from which addresses will be
    # derived deterministically and sequentially. Current sequence number,
    # however, is determined by the #next_address_counter property set when an object
    # is created. We do not store neither pubkey, nor the incrementer number anywhere.
    attr_reader :pubkey

    # Amount is always an Integer, in Satoshis
    attr_reader :amount

    def initialize(
      amount:, pubkey:,
      next_address_counter:   0,
      confirmations_required: 0,
      sources: Order::SOURCES,
      status_check_schedule: nil
    )
      @pubkey                 = pubkey
      @next_address_counter   = next_address_counter
      @confirmations_required = confirmations_required
      @created_at             = Time.now
      @sources                = sources
      @status_check_schedule  = nil

      raise Order::IncorrectAmount if amount.nil? || !amount.kind_of?(Integer) || amount <= 0
      @amount = amount # In satoshis

      start_periodic_status_check
    end

    # Returns a Base58-encoded Bitcoin address to which the payment transaction
    # is expected to arrive.
    def address
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
      # if reload true
        # asks one of the (or all) @sources to reload all transactions for the current address
    end

    # Last transaction made to the address. Always use this method to check whether a transaction
    # for this order has arrived. We pick last and not first because an address may be reused and we
    # always assume it's the last transaction that we want to check.
    def transaction(reload: false)
      # if reload true
        # asks one of the (or all) @sources to reload info about the transaction with that id
    end

    # Checks #transaction and returns one of the STATUSES based
    # on the meaning of each status and the contents of transaction
    # If as_string is set to true, then each status is returned as Symbol, otherwise
    # an equivalent Integer from STATUSES is returned.
    def status(as_sym: false, reload: false)
    end

    # Starts a loop which calls #status(reload: true) according to the schedule
    # determined in @status_check_schedule
    def start_periodic_status_check
      return if @status_check_schedule.nil? || status > 1
      # TODO: implementation of the schedule loop
    end

  end

end
