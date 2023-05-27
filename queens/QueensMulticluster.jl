
include("queens_params.jl")
include("queens_base.jl")
include("queens_cpu_base.jl")
include("queens_gpu_base.jl")

using Hash

@computation multicluster QueensMulticluster begin

    using Distributed

    @unit master begin

        function queens(size; cutoff_depth = 5)

            size += 1
        
            (subproblems, partial_tree_size) = Main.queens_partial_search(Val(size), cutoff_depth)
        
            number_of_solutions, tree_size = queens(size, cutoff_depth, subproblems) 
            tree_size += partial_tree_size
        
            return number_of_solutions, tree_size
        
        end #caller

        function queens(size, cutoff_depth, subproblems) 

            number_of_subproblems = length(subproblems)
            num_workers = length(topology[:worker])
            proc_tree_size = zeros(Int64, num_workers)
            proc_num_sols  = zeros(Int64, num_workers)
            proc_load = fill(div(number_of_subproblems, num_workers), num_workers)
            proc_load[num_workers] += mod(number_of_subproblems, num_workers)
        
            result = Dict()
        
            idx = 1 
                
            for i in 1:length(topology[:worker])        
                local local_load = proc_load[i]
        
                local_subproblems = subproblems[idx:(idx + local_load - 1)]
                idx += local_load
        
                result[i] = @remotecall topology[:worker][i] begin
                    @info "SENDING WORKLOAD TO $(topology[:worker][i]) *** size = $size, cutoff_depth = $cutoff_depth, local_subproblems = $local_subproblems -- BEGIN"
                    QueensMulticluster.queens_at_worker($size, $cutoff_depth, $local_subproblems)
                    @info "SENDING WORKLOAD TO $(topology[:worker][i]) *** size = $size, cutoff_depth = $cutoff_depth, local_subproblems = $local_subproblems -- END"
                end
            end
        
            for i in 1:length(topology[:worker])
                
                ns, ts = fetch(result[i])
                proc_num_sols[i]  += ns
                proc_tree_size[i] += ts       
            end
        
            number_of_solutions = sum(proc_num_sols)
            tree_size = sum(proc_tree_size)
        
            return number_of_solutions, tree_size
        
        end #caller     

        notify_unit(:master, :worker; delay_time = 30)
        wait_unit(:worker)
        
        function finish()
            for i in topology[:worker]
                @remotecall_fetch i QueensMulticluster.finish()
            end
        end

        export queens

    end

    @unit parallel count=W worker begin
        
        @inner QueensMPI

        function queens_at_worker(size, cutoff_depth, subproblems)
            QueensMPI.queens(size, cutoff_depth, subproblems)
        end

        function finish()
            QueensMPI.finish()
        end

        notify_unit(:worker, unit_idx, :master)
        wait_unit(:master)

    end


end