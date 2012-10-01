[[Build Status](https://secure.travis-ci.org/JonRowe/FiberPool.png)](http://travis-ci.org/JonRowe/FiberPool)
FiberPool
=========
An implementation of a fiber pool that can be used to cooperatively
schedule workloads.

Best used in combination with EventMachine to allow multiple workloads to be
processed at the same time.

Throttled to pool size. (default 10)
Optional completion callback.

You must call the yielded callback from pool.add add the end of your
workload.

e.g.

    EM.run do
      FiberPool.start(max_concurrency, pool_complete_callback) do |pool|
        pool.add do |job_completed|
          request = EventMachine::HttpRequest.new('http://example.com').get
          request.callback { success; job_completed.call }
          request.errback  { failure; job_completed.call }
        end
      end
    end

NB
-----
This was extracted from a running project, proper documentation may follow.
