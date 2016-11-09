# Extend the Fiber class
#
# Outline,
#
#   Fiber.await do |fiber|
#     fiber.resume response
#     fiber.leave StandardError, "Something"
#   end
require 'fiber'

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

  def leave(exception, message=nil)
    resume exception.is_a?(Class) ? exception.new(message) : exception
  end

  class <<self

    def scope(*a, &b)
      Fibre::Scope.scope(*a, &b)
    end

    def await(*a, &b)
      Fibre::Scope.in_scope? ? Fibre::Scope.await(*a, &b) : await_only(*a, &b)
    end

    # raise exception if we catch exception
    def yield!
      Fiber.yield.tap do |y|
        raise y if y.is_a?(Exception)
      end
    end

    def await_only
      yield(Fiber.current) if block_given?
      Fiber.yield!
    end
  end
end
