#
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
    events :before, :after

    # Initialize fibers pool
    def initialize(size)
      @pool = size.times.collect { ::Fiber.new(&self.method(:fiber_entry)) }
      @reserved = {}
      @queue = []
    end

    # Check-out fiber from pool
    def checkout(&b)
      spec = { block: b, parent: ::Fiber.current }

      if @pool.empty?
        raise "fiber queue overflow" if @queue.size > MAX_POOL_QUEUE_SIZE
        @queue.push spec
        return
      end

      @pool.shift.tap do |fiber|
        @reserved[fiber.object_id] = spec
        err = fiber.resume(spec)
        raise FiberError.new(err) if err.is_a?(Exception)
      end

      self
    end

    # Free pool size
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

    # entrypoint for all fibers
    def fiber_entry(spec)
      loop do
        raise "wrong spec in fiber block" unless spec.is_a?(Hash)

        result = nil
        begin
          before!(spec)
          spec[:block].call# *Fiber.current.args
          after!(spec)

          # catch ArgumentError, IOError, EOFError, IndexError, LocalJumpError, NameError, NoMethodError
          # RangeError, FloatDomainError, RegexpError, RuntimeError, SecurityError, SystemCallError
          # SystemStackError, ThreadError, TypeError, ZeroDivisionError
        rescue StandardError => e
          result = e
          # catch NoMemoryError, ScriptError, SignalException, SystemExit, fatal etc
          #rescue Exception
        end

        unless @queue.empty?
          spec = @queue.shift
          next
        end

        spec = checkin(result)
      end
    end

    # Check-in fiber to pool
    def checkin(result=nil)
      @reserved.delete ::Fiber.current.object_id
      @pool.unshift ::Fiber.current
      ::Fiber.yield result
    end
  end
end
