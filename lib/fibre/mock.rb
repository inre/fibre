module Fibre
  class Mock
    attr_reader   :scope
    attr_reader   :result
    attr_accessor :path

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
