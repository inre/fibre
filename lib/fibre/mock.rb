class Fiber
  class Mock
    attr_reader :scope
    attr_reader :result

    def initialize(scope)
      @scope = scope
    end

    def resume(result)
      @result = result
      @completed = true
      @scope.check
    end

    def completed?
      !!@completed
    end

    def leave(e, *a)
      resume e.new(*a)
    end
  end
end
