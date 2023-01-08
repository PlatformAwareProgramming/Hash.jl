using Hash

using MPI
MPI.Init()

@application messagepassing Test2 begin
    
    @inner ReadData2

    @unit master begin

        @info :master

        @slice ReadData2.producer
        
        producer.produce()
        
    end

    @unit parallel worker1 begin

        @inner P

      #  @info(":worker1 --- unit_idx = $unit_idx")
      #  @info(":worker1 --- unit_size = $(length(topology[:worker1]))")
      #  @info(":worker1 --- global_idx = $(topology[:worker1][unit_idx])")
      #  @info(":worker1 --- global_idx_cohort = $(topology[:worker1])")
      #  @info(":worker1 --- local_idx = $(local_topology[:worker1][unit_idx])")
      #  @info(":worker1 --- local_idx_cohort = $(local_topology[:worker1])")

        @slice ReadData2.consumer
        #@slice P as p_compute      # P.master is the default and "@inner P" is expected to be inside the unit.
        
        P.do_something(1)
        consumer.consume()
        
    end

    
    @unit parallel worker2 begin

        @inner Q

     #   @info(":worker2 --- unit_idx = $unit_idx")
     #   @info(":worker2 --- unit_size = $(length(topology[:worker2]))")
     #   @info(":worker2 --- global_idx = $(topology[:worker2][unit_idx])")
     #   @info(":worker2 --- global_idx_cohort = $(topology[:worker2])")
     #   @info(":worker2 --- local_idx = $(local_topology[:worker2][unit_idx])")
     #   @info(":worker2 --- local_idx_cohort = $(local_topology[:worker2])")

        @slice ReadData2.consumer
#        @slice Q as q_compute       # Q.master is the default and "@inner Q" is expected to be inside the unit.

        Q.do_something(0)
        consumer.consume()
        
    end

end
