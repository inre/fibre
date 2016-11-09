require "spec_helper"

describe Fibre do
  using EventObject
  using Fibre::Synchrony

  before { Fibre.reset }
  let(:probe) { lambda {} }
  let(:pool) { Fibre.make_pool }

  around do |examples|
    EventMachine.run_block do
      pool.checkout(&examples)
    end
  end

  class FibreTestOperation
    def initialize(number)
      @number = number
    end

    def await
      Fiber.await do |fiber|
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

    def await
      Fiber.await { |f|
        Fibre.pool.checkout do
          raise "test"
        end
      }
    end
  end

  it "waits a successful answer" do
    result = Fiber.await do |fiber|
      EM.next_tick do
        fiber.resume :success
      end
    end
    expect(result).to be :success
  end

  it "raises an expcetion and catches Fibre error" do
    expect {
      pool.checkout do
        raise "test"
      end
    }.to raise_error Fibre::FiberError
  end

  it "raises an exception during await" do
    expect {
      op = FibreTestOperationWithException.new(4)
      op.await
    }.to raise_error Fibre::FiberError
  end

  it "waits couple async requests wrapped up with Array" do
    op1 = FibreTestOperation.new(4)
    op2 = FibreTestOperation.new(7)
    res = [op1, op2].await
    expect(res[0]).to be(4)
    expect(res[1]).to be(7)
  end

  it "waits three async requests wrapped up with Hash" do
    op1 = FibreTestOperation.new(3)
    op2 = FibreTestOperation.new(13)
    op3 = FibreTestOperation.new(5)
    res = {op1: op1, op2: op2, op3: op3}.await
    expect(res).to include(op1: 3, op2: 13, op3: 5)
  end

  it "runs a lot of asynchronous operations" do
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
    }.await!

    expect(res).to include(
      op3: 5,
      ops: match_array([3,13]),
      child: include(
        op45: match_array([8, include(op5: 9)])
      )
    )
  end
end
