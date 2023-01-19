@everywhere using Hash

@everywhere @computation remotecall QueensDistributed begin

    using Distributed

    @unit master begin

        function queens(size; cutoff_depth = 5)

            size += 1
        
            (subproblems, number_of_subproblems, partial_tree_size) = Main.queens_partial_search(Val(size), cutoff_depth)
        
            number_of_solutions, tree_size = queens(size, cutoff_depth, number_of_subproblems, subproblems) 
            tree_size += partial_tree_size
        
            return number_of_solutions, tree_size
        
        end #caller

        function queens(size, cutoff_depth, number_of_subproblems, subproblems) 

            num_workers = nworkers()
            proc_tree_size = zeros(Int64, num_workers)
            proc_num_sols  = zeros(Int64, num_workers)
            proc_load = fill(div(number_of_subproblems, num_workers), num_workers)
            proc_load[num_workers] += mod(number_of_subproblems, num_workers)
        
            result = Dict()
        
            idx = 1 
        
            @info length(subproblems)
        
            for ii in 1:num_workers
        
                local local_proc_id = ii + 1
                local local_load = proc_load[ii]
        
                @info idx, local_load
                local_subproblems = subproblems[idx:(idx + local_load - 1)]
                idx += local_load
        
                result[ii] = @spawnat local_proc_id begin
                    @info  "process $(string(local_proc_id)) has $(string(local_load)) iterations"
                    queens_at_worker(size, cutoff_depth, local_load, local_subproblems)
                end
            end
        
            for ii in 1:num_workers
                ns, ts = fetch(result[ii])
                proc_num_sols[ii]  += ns
                proc_tree_size[ii] += ts       
            end
        
            number_of_solutions = sum(proc_num_sols)
            tree_size = sum(proc_tree_size)
        
            return number_of_solutions, tree_size
        
        end #caller

    end
    
    @unit parallel count=W worker begin

        @inner QueensManycore

        function queens_at_worker(size, cutoff_depth, number_of_subproblems, subproblems)
            QueensManycore.queens(size, cutoff_depth, number_of_subproblems, subproblems)
        end
    
    end
    
end