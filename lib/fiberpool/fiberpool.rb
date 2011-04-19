require 'fiber'

class FiberPool
  attr_accessor :fibers, :pool_size, :pool_fiber

  def initialize(pool_size=10)
    self.pool_size    = pool_size
    self.fibers       = []
    self.pool_fiber  = Fiber.current
  end

  def self.start(pool_size=10, finished_callback=nil, &block)
    Fiber.new do
      pool = FiberPool.new(pool_size)
      yield pool
      pool.drain
      finished_callback.call() if finished_callback
    end.resume
  end

  def add(&block)
    fiber = Fiber.new do
      f = Fiber.current
      completion_callback = proc do
        pool_fiber.transfer(f)
      end
      yield completion_callback
    end
    add_to_pool(fiber)
  end

  def add_to_pool(fiber)
    wait_for_free_pool_space if over_capacity?
    fibers << fiber
    remove_fiber_from_pool fiber.resume
  end

  def wait_for_free_pool_space
    remove_fiber_from_pool(wait_for_next_complete_fiber)
  end

  def wait_for_next_complete_fiber
    Fiber.yield
  end

  def over_capacity?
    fibers_in_use >= pool_size
  end

  def fibers_in_use
    fibers.size
  end

  def fibers_left_to_process?
    fibers_in_use > 0
  end

  def remove_fiber_from_pool(fiber)
    fibers.delete(fiber)
  end

  def drain
    wait_for_free_pool_space while fibers_left_to_process?
  end
end
