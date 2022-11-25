    
@everywhere module Test

    ARGS = ["a","b"]
    include("ReadData.jl")

    module main

        import ..ReadData.producer
        
        function perform()
            @info "main 1"
            producer.produce()
            @info "main 2"
        end

    end

    module worker1

        import ..ReadData.consumer
        
        @info @__MODULE__

        function perform()
            @info "worker 1"
            x = consumer.consume()
            @info "CONSUMing $x !"
        end

    end

    module worker2

        import ..ReadData.consumer

        function perform()
            @info "worker 2"
            x = consumer.consume()
            @info "CONSUMing $x !"
        end

    end

    # código inserido automaticamente (cálculo da topologia e chamadda da perform)
    using Distributed

    placement = Dict()
    placement_inv = Dict()
        
    function run()

        for l in readlines("placement")
           v = split(l," ")
           id = parse(Int64,v[1])
           pr = Symbol(v[2])
           placement[id] = pr           
           w = get(placement_inv,pr,Vector())
           push!(w,id)
           placement_inv[pr] = w
        end

        which_unit = placement[Distributed.myid()]
       
        ReadData.set_placement(placement_inv,[(:main,:producer),(:worker1,:consumer),(:worker2,:consumer)])

        # the module name is passed as an argument
        this_unit = getfield(Test, which_unit#="$(ARGS[1])"=#)
        p = try getfield(this_unit, :perform) catch _ finally nothing end
        if !isnothing(p) 
           p()
        end
    end

end

@everywhere Test.run()



#=

@component Test

    @connector ReadData

    @unit main
    
        @slice ReadData.producer
    
        function perform()
            @info "main 1"
            producer.produce()
            @info "main 2"
        end
        
    end


    @unit parallel worker1
    
        @slice ReadData.consumer
    
        function perform()
            @info "worker 1"
            x = consumer.consume()
            @info "CONSUMing $x !"
        end

    end

    @unit parallel worker2
    
        @slice ReadData.consumer
    
        function perform()
            @info "worker 2"
            x = consumer.consume()
            @info "CONSUMing $x !"
        end

    end

end


=#
