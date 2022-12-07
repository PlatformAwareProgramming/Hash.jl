
using Hash

@application cluster module Test2
    
    @inner ReadData2

    @unit module main  

        @info :main

        @slice ReadData2.producer
        
        producer.produce()
        
    end

    @unit parallel module worker1

        @inner P

        @info(":worker1 --- unit_idx = $unit_idx")
        @info(":worker1 --- unit_size = $(length(global_topology[:worker1]))")
        @info(":worker1 --- global_idx = $(global_topology[:worker1][unit_idx])")
        @info(":worker1 --- global_idx_cohort = $(global_topology[:worker1])")
        @info(":worker1 --- local_idx = $(local_topology[:worker1][unit_idx])")
        @info(":worker1 --- local_idx_cohort = $(local_topology[:worker1])")

        @slice ReadData2.consumer
        @slice P as p_compute      # P.main is the default and "@inner P" is expected to be inside the unit.
        
        p_compute.do_something(1)
        consumer.consume()
        
    end

    
    @unit parallel module worker2

        @inner Q

        @info(":worker2 --- unit_idx = $unit_idx")
        @info(":worker2 --- unit_size = $(length(global_topology[:worker2]))")
        @info(":worker2 --- global_idx = $(global_topology[:worker2][unit_idx])")
        @info(":worker2 --- global_idx_cohort = $(global_topology[:worker2])")
        @info(":worker2 --- local_idx = $(local_topology[:worker2][unit_idx])")
        @info(":worker2 --- local_idx_cohort = $(local_topology[:worker2])")

        @slice ReadData2.consumer
        @slice Q as q_compute       # Q.main is the default and "@inner Q" is expected to be inside the unit.

        q_compute.do_something(0)
        consumer.consume()
        
    end

end
