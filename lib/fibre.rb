require "event_object"
require "fibre/version"
require "fibre/core_ext/fiber"
require "fibre/core_ext/synchrony"

module Fibre
  autoload :FiberPool,    'fibre/fiber_pool'
  autoload :Mock,         'fibre/mock'
  autoload :Scope,        'fibre/scope'

  module Rack
    autoload :FiberPool,  'fibre/rack/fiber_pool'
  end

  class LeaveError < StandardError; end

  # Configuration module

  extend self

  # Fiber.root - root fiber
  attr_accessor :root
  self.root = Fiber.current

  # Pool size can be set before pool initialized
  attr_accessor :pool_size
  self.pool_size = 20

  # Initialize with default pool_size
  attr_writer :pool
  def pool
    @pool ||= FiberPool.new(pool_size)
  end
end
