@info "ReadData ARGS=$ARGS"
    
module ReadData

    # begin - automatically inserted code
    
    @info "ReadData ARGS=$(Main.ARGS)"
    
    placement = Ref{Dict{Symbol,Vector{Int}}}(Dict())
    
    function set_placement(d,m)
        for (k,v) in m
            t = get(placement[],v,Vector())
            push!(t,d[k]...)        
            placement[][v] = t
        end
        @info "placement $(placement[])"
    end
        
    getPlacement(k) = placement[][k]    
        
    export getPlacement
    
    # end - automatically inserted code

    module producer

        data = Ref{Int}(888)

        function produce()
            data[] = 777
        end
        
        function fetch_data()
            @info "fetch_data"
            return data[]
        end

    end

    module consumer

        using ..producer 
        import Distributed
        using ..ReadData

        function consume()
            @info "CONSUME !"
            sleep(2)
            for i in getPlacement(:producer)  #placement[][:producer]
               x = Distributed.@fetchfrom i producer.fetch_data()
               println(x)
            end
        end

    end

end

#=

@component ReadData

    @unit producer
        
        data = Ref{Int}(888)

        function produce()
            data[] = 777
        end
        
        function fetch_data()
            @info "fetch_data"
            return data[]
        end
        
    end
    
    
    @unit parallel consumer
        
        import Distributed

        function consume()
            @info "CONSUME !"
            sleep(2)
            for i in placement[][:producer]
               x = Distributed.@fetchfrom i producer.fetch_data()
               println(x)
            end
            println(x)
        end
        
    end

end

=#
