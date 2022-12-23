using Hash
 
@connector messagepassing ReadData2 begin

    @unit single producer begin
        
       # @info(":producer --- unit_idx = $unit_idx")
       # @info(":producer --- unit_size = $(length(global_topology[:producer]))")
       # @info(":producer --- global_idx = $(global_topology[:producer][unit_idx])")
       # @info(":producer --- global_idx_cohort = $(global_topology[:producer])")
       # @info(":producer --- local_idx = $(local_topology[:producer][unit_idx])")
       # @info(":producer --- local_idx_cohort = $(local_topology[:producer])")
       # @info(":producer --- global_topology = $global_topology")
       # @info(":producer --- local_topology = $local_topology")

        using MPI
        comm = MPI.COMM_WORLD

        function produce()
           # @info "PRODUCE! $(global_topology[:consumer])"
            
            for i in global_topology[:consumer]
                MPI.send("message to $i", comm; dest=i)
            end            
        end
        
    end

    @unit parallel consumer begin
        
       # @info(":consumer --- unit_idx = $unit_idx")
       # @info(":consumer --- unit_size = $(length(global_topology[:consumer]))")
       # @info(":consumer --- global_idx = $(global_topology[:consumer][unit_idx])")
       # @info(":consumer --- global_idx_cohort = $(global_topology[:consumer])")
       # @info(":consumer --- local_idx = $(local_topology[:consumer][unit_idx])")
       # @info(":consumer --- local_idx_cohort = $(local_topology[:consumer])")

        using MPI
        comm = MPI.COMM_WORLD

        function consume()
            #   @info "CONSUME! $(global_topology[:producer])"
            msg = MPI.recv(comm;source=global_topology[:producer][1])
            @info "**************************** MESSAGE from $msg !"
        end

    end
    
end

