require "spec_helper"

describe Fibre do
  using EventObject
  using Fibre::Synchrony

  before { Fibre.reset }
  let(:probe) { lambda {} }
  let(:pool) { Fibre.make_pool }

  it "creates fiber's pool" do
    expect(Fibre.pool.pool_size).to be(50)
    expect(Fibre.pool.pool_queue_size).to be(1000)
  end

  it "initializes global pool" do
    Fibre.init_pool(pool_size: 10, pool_queue_size: 900)
    expect(Fibre.pool.pool_size).to be(10)
    expect(Fibre.pool.pool_queue_size).to be(900)
  end

  it "has the root fiber" do
    expect(Fibre.root).to equal(Fiber.current)
    expect(Fiber.current.root?).to be true
  end

  it "checks out the fiber" do
    expect(probe).to receive(:call)
    pool.checkout(&probe)
  end

  it "calls in scope" do
    expect(probe).to receive(:call)
    pool.checkout do
      Fiber.scope do
        probe.call
      end
    end
  end

  def raise_method
    raise "test exception"
  end

  it "raises an exception in the fiber" do
    expect {
      pool.checkout do
        raise_method
      end
  }.to raise_error(Fibre::FiberError)
  end

  it "catches up an exception with `error` event" do
    expect(probe).to receive(:call)
    pool.on :error do |error|
      probe.call
    end

    expect {
      pool.checkout do
        raise
      end
    }.to_not raise_error
  end
end
