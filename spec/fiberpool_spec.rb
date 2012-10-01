require 'spec_helper'

describe FiberPool do
  let(:pool) { FiberPool.new }

  describe ".start" do
    let(:fiber) { mock "fiber", :resume => nil }

    before do
      Fiber.stub(:new).and_return(fiber)
    end

    subject { FiberPool.start { |*args| @args = *args } }

    it "should create a new fiber, which will become the pool fiber" do
      Fiber.should_receive(:new).and_yield.and_return(fiber)
      subject
    end
    it "should kick off the fiber" do
      fiber.should_receive(:resume)
      subject
    end

    context "within that fiber" do
      let(:fake_pool) { mock "fake_pool", :drain => nil }

      before do
        Fiber.stub(:new).and_yield.and_return(fiber)
        FiberPool.stub(:new).and_return(fake_pool)
      end

      it "should create a new fiberpool" do
        FiberPool.should_receive(:new).and_return(fake_pool)
        subject
      end
      it "should yield the pool" do
        subject
        @args.should eq [fake_pool]
      end
      it "should drain the pool when done" do
        fake_pool.should_receive(:drain)
        subject
      end

      context "where pool size is specified" do
        subject { FiberPool.start(20) { |args| 'lal block' } }

        it "should create a new fiberpool of the correct size" do
          FiberPool.should_receive(:new).with(20).and_return(fake_pool)
          subject
        end
      end
      context "were a callback is specified" do
        let(:callback) { mock "callback" }

        subject { FiberPool.start(10, callback) { |args| 'lal block' } }

        it "should call the callback" do
          callback.should_receive(:call)
          subject
        end
      end
    end
  end

  describe "#initialize" do
    context "defaults" do
      subject { pool }

      its(:pool_size) { should eq 10 }
      its(:fibers) { should eq [] }
      its(:pool_fiber) { should = Fiber.current }
    end
    context "pool size specified" do
      let(:pool_size) { mock "pool_size" }

      subject { FiberPool.new pool_size }
      its(:pool_size) { should eq pool_size }
    end
  end

  describe "#add" do
    let(:fiber) { mock "fiber" }
    let(:completion_callback) { @callback }

    before do
      Fiber.stub(:new).and_yield.and_return(fiber)
      pool.stub(:add_to_pool)
    end

    subject { pool.add { |callback| @callback = callback } }

    it "should create a fiber" do
      Fiber.should_receive(:new).and_yield.and_return(fiber)
      subject
    end
    it "should yield a completion callback" do
      subject
      completion_callback.should be_a Proc
    end
    specify "the compleition callback should transfer the fiber back to the pool" do
      Fiber.stub(:current).and_return(fiber)
      subject
      pool.pool_fiber.should_receive(:transfer).with(fiber)
      completion_callback.call
    end
    it "should add the fiber to the pool" do
      pool.should_receive(:add_to_pool).with(fiber)
      subject
    end
  end

  describe "#add_to_pool" do
    let(:completed_fiber) { mock "completed_fiber" }
    let(:fiber) { mock "fiber", :resume => completed_fiber }

    subject { pool.add_to_pool fiber }

    context "where the pool is over capacity" do
      before { pool.stub(:over_capacity?).and_return(true) }
      it "should wait for free pool space" do
        pool.should_receive(:wait_for_free_pool_space)
        subject
      end
    end
    it "should store the paused fiber in the pool" do
      subject
      pool.fibers.should == [fiber]
      #note, normally the fiber would be removed at the end of the method
      #but mocks are allowing this to be inspected
    end
    it "should kick off the fiber" do
      fiber.should_receive(:resume).and_return(completed_fiber)
      subject
    end
    it "should remove the fiber when finished" do
      pool.should_receive(:remove_fiber_from_pool).with(completed_fiber)
      subject
    end
  end

  describe "#wait_for_free_pool_space" do
    let(:completed_fiber) { mock "completed_fiber" }

    before { pool.stub(:wait_for_next_complete_fiber).and_return(completed_fiber) }

    subject { pool.wait_for_free_pool_space }

    it "should wait for the next complete fiber" do
      pool.should_receive(:wait_for_next_complete_fiber).and_return(completed_fiber)
      subject
    end
    it "should remove that fiber from the pool" do
      pool.should_receive(:remove_fiber_from_pool).with(completed_fiber)
      subject
    end
  end

  describe "#wait_for_next_complete_fiber" do
    it "should yield back to the original calling context" do
      Fiber.should_receive(:yield)
      pool.wait_for_next_complete_fiber
    end
  end

  describe "#over_capacity?" do
    before { pool.fibers = [mock,mock,mock] }
    subject { pool.over_capacity? }

    context "where pool size equals fibers in use" do
      before { pool.pool_size = pool.fibers.size }
      it { should be_true }
    end
    context "where pool size is greater than fibers in use" do
      before { pool.pool_size = pool.fibers.size + 1 }
      it { should be_false }
    end
    context "where pool size is less than fibers in use" do
      before { pool.pool_size = pool.fibers.size - 1 }
      it { should be_true }
    end
  end

  describe "#fibers_in_use" do
    it "should return the size of the fibers array" do
      pool.fibers = [mock,mock,mock]
      pool.fibers_in_use.should eq 3
    end
  end

  describe "#fibers_left_to_process" do
    subject { pool.fibers_left_to_process? }

    context "where there are fibers in use" do
      before { pool.stub(:fibers_in_use).and_return(3) }
      it { should be_true }
    end
    context "where there are no fibers left to process" do
      before { pool.stub(:fibers_in_use).and_return(0) }
      it { should be_false }
    end
  end

  describe "#remove_fiber_from_pool" do
    let(:fiber) { mock "fiber" }

    before { pool.fibers = [fiber] }

    it "should remove the fiber from the pool" do
      pool.remove_fiber_from_pool fiber 
      pool.fibers.should == []
    end
    it "should do nothing if it isnt in the pool" do
      pool.remove_fiber_from_pool mock("not in the pool")
      pool.fibers.should == [fiber]
    end
  end

  describe "#drain" do
    before { pool.stub(:fibers_left_to_process?).and_return(true,true,false) }

    it "should wait for free pool space while there are fibers left to process" do
      pool.should_receive(:wait_for_free_pool_space).exactly(:twice)
      pool.drain
    end
  end
end
