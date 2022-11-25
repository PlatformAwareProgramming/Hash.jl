module Multiscale

    @connector Comm
    @connector SendRecv
    @connector ReadData
    @computation C

    @unit Main

        @slice SendRecv.receiver 
        @slice ReadData.producer 

        function perform()
            producer.produce()
            acc = receiver.recv()
            println("The result is $acc")
        end

    end

    @unit parallel unit_a

        @slice P as p_compute        # slice renaming
        @slice Comm.peer as comm
        @slice ReadData.consumer 
        @slice C.worker as w

        function perform()
            x = w.process(consumer.consume())
            result_a = p_compute.do_something(x)
            comm.send(result_a)
        end    
        
    end

    @unit unit_x

        @slice SendRecv.sender as s
        @slice Comm.root as r
        
        function process_result(result)
            @info "process_result $result"
            return result
        end
     
        function perform()
            acc = 0
            for result in r.collect()
              acc += process_result(result)
            end

            s.send(acc)
        end
        
    end


    @unit parallel unit_b

        @slice Q as q_compute        
        @slice Comm.peer as comm        
        @slice ReadData.consumer as c        
        @slice C.worker as w
        
        function perform()
            x = w.process(c.consume())
            result_b = q_compute.do_something(x)
            comm.send(result_b)
        end
    end

end

