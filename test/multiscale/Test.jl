
 #@everywhere begin cd("/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl"); import Pkg; Pkg.activate(".") end
 
@everywhere using Hash

@everywhere @application remotecall Test begin
    
    @inner ReadData

    @unit master begin

        @info :master

        @slice ReadData.producer
        
        producer.produce()
        
    end

    @unit parallel worker1 begin

        @inner P

        @info(":worker1 --- unit_idx = $unit_idx")
        @info(":worker1 --- unit_size = $(length(topology[:worker1]))")
        @info(":worker1 --- global_idx = $(topology[:worker1][unit_idx])")
        @info(":worker1 --- global_idx_cohort = $(topology[:worker1])")
        @info(":worker1 --- local_idx = $(local_topology[:worker1][unit_idx])")
        @info(":worker1 --- local_idx_cohort = $(local_topology[:worker1])")

        @slice ReadData.consumer
        
        P.do_something(1)
        consumer.consume()
        
    end

    
    @unit parallel worker2 begin

        @inner Q

        @info(":worker2 --- unit_idx = $unit_idx")
        @info(":worker2 --- unit_size = $(length(topology[:worker2]))")
        @info(":worker2 --- global_idx = $(topology[:worker2][unit_idx])")
        @info(":worker2 --- global_idx_cohort = $(topology[:worker2])")
        @info(":worker2 --- local_idx = $(local_topology[:worker2][unit_idx])")
        @info(":worker2 --- local_idx_cohort = $(local_topology[:worker2])")

        @slice ReadData.consumer

        Q.do_something(0)
        consumer.consume()
        
    end

end
