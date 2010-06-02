class SimpleThreadPool
  class << self
    def start_up(thread_count)
      @thread_work_queues = {}
      @locks = {}
      @threads = []
      @current_jobs = {}
      thread_count.times do |i|
        @thread_work_queues[i] = []
        @locks[i] = Mutex.new
        @threads << Thread.new(i,@thread_work_queues[i],@locks[i],@current_jobs) do |index,queue,lock,executing_jobs|
          
          while true
            if queue.size > 0
              #do the mutex
              job = nil
              lock.synchronize { 
                job = queue.slice!(0) 
              }
              if job
                executing_jobs[index] = job
                job[:block].call(job[:args])
                executing_jobs.delete(index)
              end
              
            end
            #keep looking for work until the parent pid dies
            #puts "Worker-#{index} out of stuff to do"
            sleep(0.1)
          end
             
        end
      end
    end
    
    def give_work( *args,&block)
      min = -1
      min_key = nil
      @thread_work_queues.each_pair do |k,v|
        if min_key == nil or v.size < min
          min = v.size
          min_key = k
        end
      end
      @thread_work_queues[min_key]
      @locks[min_key].synchronize {
        @thread_work_queues[min_key] << {:block => block, :args => args}
      }
    end
    
    def queue_size
      size = 0
      @thread_work_queues.each_pair do |k,v|
        size += v.size
      end
      size
    end
    
    def num_executing
      @current_jobs.keys.inject(0){|a,b| @current_jobs[b] ? a+ 1 : a }
    end
    
  end
end