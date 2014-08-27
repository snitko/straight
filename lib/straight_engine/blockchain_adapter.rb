module StraightEngine
  class BlockchainAdapter

    # An almost abstract class, providing guidance for the interfaces of
    # all blockchain adapters as well as supplying some useful methods.
    
    # Raised when blockchain data cannot be retrived for any reason.
    # We're not really intereste in the precise reason, although it is
    # stored in the message.
    class RequestError < Exception; end

    @@adapters = []

    class << self
      
      # Registers an adapter as the one that's available.
      # If an Exception is raised while working with one adapter,
      # the message is simply passed on to another one.
      def register_adapter(a)
        @@adapters << a
      end

      def method_missing(method_name, *args)
        puts "#{method_name}, #{args.inspect}"
        exception = nil
        @@adapters.each do |a|
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
end
