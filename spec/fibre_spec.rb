require "spec_helper"
describe Fibre do
  using EventObject

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

  it "rescue error in fiber" do
    expect(probe).to receive(:call)
    Fibre.pool.on(:error, &probe)
    Fibre.pool.checkout do
      raise
    end
  end
end
