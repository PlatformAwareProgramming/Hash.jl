
include("queens_base.jl")
include("queens_cpu_base.jl")

using Hash

@computation multicluster QueensMulticluster begin

    using Distributed

    @unit master begin

        cutoff_depth = 2

        @info "------------------------------------------ MASTER 1"

        function queens(size; cutoff_depth = 3)

            size += 1

            local_visited, local_permutation = Main.createArrays(Val(size))

            queens(size, 1, local_visited, local_permutation)
        
        end #caller

        function queens(size, cutoff_depth_initial, local_visited, local_permutation) 

            (subproblems, partial_tree_size) = Main.queens_partial_search(cutoff_depth_initial, cutoff_depth_initial + 1, cutoff_depth_initial + cutoff_depth, size, local_visited, local_permutation)
            number_of_subproblems = length(subproblems) #+ number_of_subproblems_initial

            num_workers = nworkers()
            proc_tree_size = zeros(Int64, num_workers)
            proc_num_sols  = zeros(Int64, num_workers)
            proc_load = fill(div(number_of_subproblems, num_workers), num_workers)
            proc_load[num_workers] += mod(number_of_subproblems, num_workers)
        
            result = Dict()
        
            idx = 1 
                
            for ii in 1:num_workers
        
                local local_proc_id = ii + 1
                local local_load = proc_load[ii]
        
                @info idx, local_load
                local_subproblems = subproblems[idx:(idx + local_load - 1)]
                idx += local_load
        
                current_cutoff_depth = cutoff_depth_initial + cutoff_depth
                result[ii] = @remotecall local_proc_id begin
                    QueensMulticluster.queens_at_worker($size, $current_cutoff_depth, $local_subproblems)
                end
            end
        
            for ii in 1:num_workers
                ns, ts = fetch(result[ii])
                proc_num_sols[ii]  += ns
                proc_tree_size[ii] += ts       
            end
        
            number_of_solutions = sum(proc_num_sols)
            tree_size = sum(proc_tree_size) + partial_tree_size
        
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
            number_of_solutions = 0
            tree_size = 0
            for (local_visited, local_permutation) in subproblems                 
                @info "................................. $number_of_solutions $tree_size 1"
                ns, ts = QueensMPI.queens(size, cutoff_depth, local_visited, local_permutation)
                number_of_solutions += ns
                tree_size += ts
                @info "................................. $ns $ts 2"
                end
            @info "................................. $number_of_solutions $tree_size 3"
            return number_of_solutions, tree_size
        end

        function finish()
            QueensMPI.finish()
        end

        notify_unit(:worker, unit_idx, :master)
        @info "WAIT MASTER 1"
        wait_unit(:master)
        @info "WAIT MASTER 2"

    end


end