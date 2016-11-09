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

    attr_reader :pool_size
    attr_reader :pool_queue_size
    attr_reader :reserved
    attr_reader :queue

    # Initialize fiber's pool
    def initialize(pool_size: DEFAULT_POOL_SIZE, pool_queue_size: DEFAULT_POOL_QUEUE_SIZE)
      @pool_size = pool_size
      @pool_queue_size = pool_queue_size
      @reserved = {}
      @queue = []
      @pool = @pool_size.times.collect { ::Fiber.new(&self.method(:fiber_entry)) }
    end

    # Borrow fiber from the pool and call the block inside
    def checkout(&b)
      spec = { block: b, parent: ::Fiber.current }

      if @pool.empty?
        raise "The fiber queue has been overflowed" if @queue.size > @pool_queue_size
        @queue.push spec
        return
      end

      @pool.shift.tap do |fiber|
        @reserved[fiber.object_id] = spec
        fiber.resume(spec)
      end

      self
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
