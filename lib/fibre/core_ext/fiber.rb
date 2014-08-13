require 'fiber'

#
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
      Fiber::Scope.scope(*a, &b)
    end

    def sync(*a, &b)
      Fiber::Scope.scope? ? Fiber::Scope.sync(*a, &b) : sync_it(*a, &b)
    end

    # raise exception if we catch exception
    def yield!
      Fiber.yield.tap do |y|
        raise y if y.is_a?(Exception)
      end
    end

    #
    # Fiber.sync do |fiber|
    #   fiber.resume # ...
    # end
    #
    def sync_it
      yield(Fiber.current) if block_given?
      Fiber.yield!
    end
  end

  def leave(exception, message=nil)
    resume exception.new(message)
  end
end
