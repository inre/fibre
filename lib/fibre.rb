require 'event_object'
require 'fibre/version'
require 'fibre/core_ext/fiber'
require 'fibre/core_ext/synchrony'
require 'fibre/fiber_error'
require 'fibre/fiber_pool'

module Fibre
  autoload :Mock, 'fibre/mock'
  autoload :Scope, 'fibre/scope'

  module Rack
    autoload :FiberPool, 'fibre/rack/fiber_pool'
  end

  extend self

  # Establish the root fiber
  attr_accessor :root
  self.root = Fiber.current

  # The pool size must be defined before the pool is called
  attr_accessor :pool_size
  self.pool_size = 50

  # Can be changed at any time
  attr_accessor :max_pool_queue_size
  self.max_pool_queue_size = 1000

  # Auto-initialize at first call and each thread has own fiber pool
  attr_writer :pool
  def pool
    Thread.current[:__fiber_pool] ||= FiberPool.new(pool_size)
  end

  def reset
    Thread.current[:__fiber_pool] = nil
    pool
  end
end
