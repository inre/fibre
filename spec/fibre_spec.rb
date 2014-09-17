require "spec_helper"

describe Fibre do
  using EventObject

  before { Fibre.pool = nil }

  it "should create default pool with default size" do
    expect(Fibre.pool.size).to be(20)
  end

  it "should have right root fiber" do
    expect(Fibre.root).to equal(Fiber.current)
    expect(Fiber.current.root?).to be true
  end

  let(:probe) { lambda {} }

  it "should checkout fiber" do
    expect(probe).to receive(:call)
    Fibre.pool.checkout(&probe)
  end

  it "should rescue error in fiber" do
    expect(probe).to receive(:call)
    Fibre.pool.on(:error) do |error|
      probe.call
    end

    Fibre.pool.checkout do
      raise
    end
  end

  it "should scope" do
    expect(probe).to receive(:call)
    Fibre.pool.checkout do
      Fiber.scope do
        probe.call
      end
    end
  end

  it "should raise uncatched exceptions" do
    expect {
      Fibre.pool.checkout do
        raise
      end
    }.to raise_error
  end

  it "should catch exception" do
    Fibre.pool.on :error do |error|
      # catch exception here
    end

    expect {
      Fibre.pool.checkout do
        raise
      end
    }.to_not raise_error
  end
end
