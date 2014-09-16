module Fibre
  class Scope
    attr_accessor :mocks
    attr_accessor :fiber

    class <<self

      def scope
        raise "nested scopes" if Fiber.current[:scope]
        Fiber.current[:scope] = self.new(Fiber.current)
        res = yield
        Fiber.current[:scope] = nil
        Fiber.yield!
        res
      end

      def scope?
        !!Fiber.current[:scope]
      end

      def sync
        scope = Fiber.current[:scope]
        mock = Fiber::Mock.new(scope)
        scope.mocks << mock
        yield(mock) if block_given?
        mock
      end
    end

    def initialize(fiber)
      @fiber = fiber
      @mocks = []
    end

    def check
      fiber.resume if @mocks.all?(&:completed?)
    end

    module Iterator
      def sync
        res = Fiber.scope do
          collect(&:sync)
        end
        res.collect(&:result)
      end
    end
  end
end
