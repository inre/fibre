require 'fiber'

#   Fiber.sync do |fiber|
#     fiber.resume response
#     fiber.leave StandardError, "Something"
#   end

class Fiber

  def attributes
    @attributes ||= {}
  end

  def root?
    self.eql? Fibre.root
  end

  def [](key)
    attributes[key]
  end

  def []=(key,value)
    attributes[key] = value
  end

  class <<self

    def scope(*a, &b)
      Fibre::Scope.scope(*a, &b)
    end

    def sync(*a, &b)
      Fibre::Scope.scope? ? Fibre::Scope.sync(*a, &b) : wait(*a, &b)
    end

    # raise exception if we catch exception
    def yield!
      Fiber.yield.tap do |y|
        raise Fibre::FiberError.new(y) if y.is_a?(Exception)
      end
    end

    def wait
      yield(Fiber.current) if block_given?
      Fiber.yield!
    end
  end

  def leave(exception, message=nil) # deprecated
    raise exception.new(message)
  end
end
