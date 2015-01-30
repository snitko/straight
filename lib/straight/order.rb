module Straight

  # This module should be included into your own class to extend it with Order functionality.
  # For example, if you have a ActiveRecord model called Order, you can include OrderModule into it
  # and you'll now be able to do everything to check order's status, but you'll also get AR Database storage
  # funcionality, its validations etc.
  #
  # The right way to implement this would be to do it the other way: inherit from Straight::Order, then
  # include ActiveRecord, but at this point ActiveRecord doesn't work this way. Furthermore, some other libraries, like Sequel,
  # also require you to inherit from them. Thus, the module.
  #
  # When this module is included, it doesn't actually *include* all the methods, some are prepended (see Ruby docs on #prepend).
  # It is important specifically for getters and setters and as a general rule only getters and setters are prepended.
  #
  # If you don't want to bother yourself with modules, please use Straight::Order class and simply create new instances of it.
  # However, if you are contributing to the library, all new funcionality should go to either Straight::OrderModule::Includable or
  # Straight::OrderModule::Prependable (most likely the former).
  module OrderModule

    # Only add getters and setters for those properties in the extended class
    # that don't already have them. This is very useful with ActiveRecord for example
    # where we don't want to override AR getters and setters that set attribtues.
    def self.included(base)
      base.class_eval do
        [:amount, :address, :gateway, :keychain_id, :status, :tid].each do |field|
          attr_reader field unless base.method_defined?(field)
          attr_writer field unless base.method_defined?("#{field}=")
        end
        prepend Prependable
        include Includable
      end
    end

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

    # If you are defining methods in this module, it means you most likely want to
    # call super() somehwere inside those methods. An example would be the #status=
    # setter. We do our thing, then call super() so that the class this module is prepended to
    # could do its thing. For instance, if we included it into ActiveRecord, then after
    # #status= is executed, it would call ActiveRecord model setter #status=
    #
    # In short, the idea is to let the class we're being prepended to do its magic
    # after out methods are finished.
    module Prependable

      # Checks #transaction and returns one of the STATUSES based
      # on the meaning of each status and the contents of transaction
      # If as_sym is set to true, then each status is returned as Symbol, otherwise
      # an equivalent Integer from STATUSES is returned.
      def status(as_sym: false, reload: false)

        if defined?(super)
          begin 
            @status = super
          # if no method with arguments found in the class
          # we're prepending to, then let's use a standard getter
          # with no argument.
          rescue ArgumentError
            @status = super()
          end
        end

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
            if t[:confirmations] >= gateway.confirmations_required
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

        self.tid = transaction[:tid] if transaction
        
        # Pay special attention to the order of these statements. If you place
        # the assignment @status = new_status below the callback call,
        # you may get a "Stack level too deep" error if the callback checks
        # for the status and it's nil (therefore, force reload and the cycle continues).
        # 
        # The order in which these statements currently are prevents that error, because
        # by the time a callback checks the status it's already set.
        @status_changed = (@status != new_status)
        @status         = new_status
        gateway.order_status_changed(self) if status_changed?
        super if defined?(super)
      end

      def status_changed?
        @status_changed
      end

    end

    module Includable

      # Returns an array of transactions for the order's address, each as a hash:
      #   [ {tid: "feba9e7bfea...", amount: 1202000, ...} ]
      #
      # An order is supposed to have only one transaction to its address, but we cannot
      # always guarantee that (especially when a merchant decides to reuse the address
      # for some reason -- he shouldn't but you know people).
      #
      # Therefore, this method returns all of the transactions.
      # For compliance, there's also a #transaction method which always returns
      # the last transaction made to the address.
      def transactions(reload: false)
        @transactions = gateway.fetch_transactions_for(address) if reload || !@transactions
        @transactions
      end

      # Last transaction made to the address. Always use this method to check whether a transaction
      # for this order has arrived. We pick last and not first because an address may be reused and we
      # always assume it's the last transaction that we want to check.
      def transaction(reload: false)
        transactions(reload: reload).first
      end

      # Starts a loop which calls #status(reload: true) according to the schedule
      # determined in @status_check_schedule. This method is supposed to be
      # called in a separate thread, for example:
      #
      #   Thread.new do
      #     order.start_periodic_status_check
      #   end
      #
      # `duration` argument (value is in seconds) allows you to
      # control in what time an order expires. In other words, we
      # keep checking for new transactions until the time passes.
      # Then we stop and set Order's status to STATUS[:expired]. See
      # #check_status_on_schedule for the implementation details.
      def start_periodic_status_check(duration: 600)
        check_status_on_schedule(duration: duration)
      end
      
      # Recursion here! Keeps calling itself according to the schedule until
      # either the status changes or the schedule tells it to stop.
      def check_status_on_schedule(period: 10, iteration_index: 0, duration: 600, time_passed: 0)
        self.status(reload: true)
        time_passed += period
        if duration >= time_passed # Stop checking if status is >= 2
          if self.status < 2
            schedule = gateway.status_check_schedule.call(period, iteration_index)
            sleep period
            check_status_on_schedule(
              period:          schedule[:period],
              iteration_index: schedule[:iteration_index],
              duration:        duration,
              time_passed:     time_passed
            )
          end
        elsif self.status < 2
          self.status = STATUSES[:expired]
        end
      end

      def to_json
        to_h.to_json
      end

      def to_h
        { status: status, amount: amount, address: address, tid: tid }
      end

      def amount_in_btc(as: :number)
        a = Satoshi.new(amount, from_unit: :satoshi, to_unit: :btc)
        as == :string ? a.to_unit(as: :string) : a.to_unit
      end

    end

  end

  # Instances of this class are generated when we'd like to start watching
  # some addresses to check whether a transaction containing a certain amount
  # has arrived to it.
  #
  # It is worth noting that instances do not know how store themselves anywhere,
  # so as the class is written here, those instances are only supposed to exist
  # in memory. Storing orders is entirely up to you.
  class Order
    include OrderModule

    def initialize
      @status = 0
    end

  end

end
