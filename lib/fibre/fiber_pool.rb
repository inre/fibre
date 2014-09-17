#
# Fiber pool
#
# Example,
#  using EventObject
#  pool = Fibre::FiberPool.new(10)
#  pool.checkout do
#    puts "runned in fiber"
#  end
#
#  # some fiber raised exception
#  pool.on :error do |e|
#    puts e.to_s
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

    # Check-out fiber from pool
    def checkout(&b)
      spec = { block: b, parent: ::Fiber.current }

      if @pool.empty?
        raise "fiber queue overflow" if @queue.size > MAX_POOL_QUEUE_SIZE
        @queue.push spec
        return
      end

      @pool.shift.tap do |fiber|
        @reserved[fiber.object_id] = fiber
        fiber.resume(spec)
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

        begin
          before!(spec)
          spec[:block].call# *Fiber.current.args
          after!(spec)
        rescue StandardError => e
          raise e if error.empty?
          error!(e)
        end

        unless @queue.empty?
          spec = @queue.shift
          next
        end

        spec = checkin
      end
    end

    # Check-in fiber to pool
    def checkin
      @reserved.delete ::Fiber.current.object_id
      @pool.unshift ::Fiber.current
      ::Fiber.yield
    end
  end
end
