using Hash
 
@connector cluster ReadData begin

    @unit single producer begin
        
        @info(":producer --- unit_idx = $unit_idx")
        @info(":producer --- unit_size = $(length(topology[:producer]))")
        @info(":producer --- global_idx = $(topology[:producer][unit_idx])")
        @info(":producer --- global_idx_cohort = $(topology[:producer])")
        @info(":producer --- local_idx = $(local_topology[:producer][unit_idx])")
        @info(":producer --- local_idx_cohort = $(local_topology[:producer])")
        @info(":producer --- topology = $topology")
        @info(":producer --- local_topology = $local_topology")

        function produce()
            @info "PRODUCE! $(topology[:consumer])"
        end
        
    end

    @unit parallel consumer begin
        
        @info(":consumer --- unit_idx = $unit_idx")
        @info(":consumer --- unit_size = $(length(topology[:consumer]))")
        @info(":consumer --- global_idx = $(topology[:consumer][unit_idx])")
        @info(":consumer --- global_idx_cohort = $(topology[:consumer])")
        @info(":consumer --- local_idx = $(local_topology[:consumer][unit_idx])")
        @info(":consumer --- local_idx_cohort = $(local_topology[:consumer])")

        function consume()
            @info "CONSUME! $(topology[:producer])"
            #@info "**************************** MESSAGE from $msg !"
        end

    end
    
end

