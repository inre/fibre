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

  DEFAULT_POOL_SIZE = 50
  DEFAULT_POOL_QUEUE_SIZE = 1000
  FIBER_POOL_THREADED = '__fiber_pool'

  def make_pool(pool_size: DEFAULT_POOL_SIZE, pool_queue_size: DEFAULT_POOL_QUEUE_SIZE)
    FiberPool.new(pool_size: pool_size, pool_queue_size: pool_queue_size)
  end

  # Auto-initialize at first call and each thread has own fiber pool
  def pool
    Thread.current[FIBER_POOL_THREADED] ||= make_pool
  end

  def reset
    Thread.current[FIBER_POOL_THREADED] = nil
    pool
  end
end
