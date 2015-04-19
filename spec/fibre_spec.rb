require "spec_helper"

describe Fibre do
  using EventObject
  using Fibre::Synchrony

  before { Fibre.pool = nil }
  let(:probe) { lambda {} }

  it "should create default pool with default size" do
    expect(Fibre.pool.size).to be(20)
  end

  it "should have right root fiber" do
    expect(Fibre.root).to equal(Fiber.current)
    expect(Fiber.current.root?).to be true
  end


  it "should checkout fiber" do
    expect(probe).to receive(:call)
    Fibre.pool.checkout(&probe)
  end
=begin
  it "should rescue error in fiber" do
    expect(probe).to receive(:call)
    Fibre.pool.on(:error) do |error|
      probe.call
    end

    Fibre.pool.checkout do
      raise
    end
  end
=end

  it "should scope" do
    expect(probe).to receive(:call)
    Fibre.pool.checkout do
      Fiber.scope do
        probe.call
      end
    end
  end

  def raise_method
    raise "test exception"
  end

  it "should raise uncatched exceptions" do
    expect {
      Fibre.pool.checkout do
        raise_method
      end
    }.to raise_error
  end
=begin
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
=end
  describe "in fiber specs" do

    around do |examples|
      EventMachine.run_block do
        Fibre.pool.checkout(&examples)
      end
    end

    class FibreTestOperation
      def initialize(number)
        @number = number
      end

      def sync
        Fiber.sync do |fiber|
          EM.next_tick do
            fiber.resume @number
          end
        end
      end
    end

    class FibreTestOperationWithException
      def initialize(number)
        @number = number
      end

      def sync
        Fiber.sync do |f|
          Fibre.pool.checkout do
            raise "test"
          end
        end
      end
    end

    it "should Fiber.sync works well" do
      result = Fiber.sync do |fiber|
        EM.next_tick do
          fiber.resume :success
        end
      end
      expect(result).to be :success
    end

    it "should raise exception in fiber" do
      expect {
        Fibre.pool.checkout do
          raise "test"
        end
      }.to raise_error FiberError
    end

    it "should sync with exception" do
      expect {
        op = FibreTestOperationWithException.new(4)
        op.sync
      }.to raise_error FiberError
    end

    it "should sync array (scoping test)" do
      op1 = FibreTestOperation.new(4)
      op2 = FibreTestOperation.new(7)
      res = [op1, op2].sync
      expect(res[0]).to be(4)
      expect(res[1]).to be(7)
    end

    it "should sync hash" do
      op1 = FibreTestOperation.new(3)
      op2 = FibreTestOperation.new(13)
      op3 = FibreTestOperation.new(5)
      res = {op1: op1, op2: op2, op3: op3}.sync
      expect(res).to include(op1: 3, op2: 13, op3: 5)
    end

    it "should deep sync and sync! method (two in one)" do
      op1 = FibreTestOperation.new(3)
      op2 = FibreTestOperation.new(13)
      op3 = FibreTestOperation.new(5)
      op4 = FibreTestOperation.new(8)
      op5 = FibreTestOperation.new(9)
      res = {
        ops: [op1, op2],
        op3: op3,
        child: {
          op45: [op4, { op5: op5 }]
        }
      }.sync!

      expect(res).to include(
        op3: 5,
        ops: match_array([3,13]),
        child: include(
          op45: match_array([8, include(op5: 9)])
        )
      )
    end
  end
end
