# Fiber pool
#
# Example,
#  using EventObject
#  pool = Fibre::FiberPool.new(10)
#  pool.checkout do
#    puts "runned in fiber"
#  end

module Fibre
  using EventObject

  class FiberPool
    events :error, :before, :after

    # Initialize fibers pool
    def initialize(size)
      @pool = size.times.collect { ::Fiber.new(&self.method(:fiber_entry)) }
      @reserved = {}
      @queue = []
    end

    # Borrow fiber from the pool and call the block inside
    def checkout(&b)
      spec = { block: b, parent: ::Fiber.current }

      if @pool.empty?
        raise "The fiber queue has been overflowed" if @queue.size > Fibre.max_pool_queue_size
        @queue.push spec
        return
      end

      @pool.shift.tap do |fiber|
        @reserved[fiber.object_id] = spec
        fiber.resume(spec)
      end

      self
    end

    # The size of pool
    def size
      @pool.size
    end

    def reserved
      @reserved
    end

    def queue
      @queue
    end

    private

    # There is entrypoint running fibers
    def fiber_entry(spec)
      loop do
        raise "wrong spec in fiber block" unless spec.is_a?(Hash)

        begin
          before!(spec)
          spec[:block].call# *Fiber.current.args
          after!(spec)

          # catch ArgumentError, IOError, EOFError, IndexError, LocalJumpError, NameError, NoMethodError
          # RangeError, FloatDomainError, RegexpError, RuntimeError, SecurityError, SystemCallError
          # SystemStackError, ThreadError, TypeError, ZeroDivisionError
        rescue StandardError => e
          if error.empty?
            raise Fibre::FiberError.new(e)
          else
            error!(e)
          end
          # catch NoMemoryError, ScriptError, SignalException, SystemExit, fatal etc
          #rescue Exception
        end

        unless @queue.empty?
          spec = @queue.shift
          next
        end

        spec = checkin
      end
    end

    # Return the fiber into the pool
    def checkin(result=nil)
      @reserved.delete ::Fiber.current.object_id
      @pool.unshift ::Fiber.current
      ::Fiber.yield
    end
  end
end
