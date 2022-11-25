module Multiscale

    include("Comm.jl")
    include("SendRecv.jl")
    include("ReadData.jl")
    include("C.jl")
    
    # @unit Main
    module main

        @info "main"

        # @slice SendRecv.receiver as r
        import ..SendRecv.receiver
        
        # @slice ReadData.producer as p
        import ..ReadData.producer

        function perform()
            producer.produce()
            acc = receiver.recv()
            println("The result is $acc")
        end

    end
    
    using .main

    # @unit parallel unit_a
    module unit_a

        @info "unit_a"
        
        # @slice P as p_compute
        include("P.jl"); import .P as p_compute   # renaming the slice
        
        # @slice Comm.peer as comm
        import ..Comm.peer as comm
        
        #@slice ReadData.consumer as c
        import ..ReadData.consumer
        
        # @slice C.worker as w
        import ..C.worker as w

        function perform()
            x = w.process(consumer.consume())
            result_a = p_compute.do_something(x)
            comm.send(result_a)
        end    
        
    end

    # @unit unit_x
    module unit_x

        @info "unit_x"
        
        # @slice SendRecv.sender as s
        import ..SendRecv.sender 

        # @slice Comm.root as r
        import ..Comm.root as r
        
        function process_result(result)
            @info "process_result $result"
            return result
        end
     
        function perform()
            acc = 0
            for result in r.collect()
              acc += process_result(result)
            end

            sender.send(acc)
        end
        
    end

    # @unit parallel unit_b
    module unit_b

        @info "unit_b"
        
        # @slice Q as q_compute
        include("Q.jl"); import .Q as q_compute
        
        # @slice Comm.peer as comm
        import ..Comm.peer as comm
        
        # @slice ReadData.consumer as c
        import ..ReadData.consumer as c
        
        # @slice C.worker as w
        import ..C.worker as w

        function perform()
            x = w.process(c.consume())
            result_b = q_compute.do_something(x)
            comm.send(result_b)
        end
    end

end

# the module name is passed as an argument
this_unit = getfield(Multiscale, Meta.parse("$(ARGS[1])"))
p = try getfield(this_unit, :perform) catch _ finally nothing end
if !isnothing(p) 
   p()
end


