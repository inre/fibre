module Fibre
  class Scope
    attr_accessor :mocks
    attr_accessor :fiber

    class <<self

      def scope
        raise 'nested scopes' if Fiber.current[:scope]
        scope = self.new(Fiber.current)
        Fiber.current[:scope] = scope
        yield
        Fiber.current[:scope] = nil
        Fiber.yield!
        scope.mocks
      end

      def in_scope?
        !!Fiber.current[:scope]
      end

      def await
        scope = Fiber.current[:scope]
        mock = Fibre::Mock.new(scope)
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
  end
end
