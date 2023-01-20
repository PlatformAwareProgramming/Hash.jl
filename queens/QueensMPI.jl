using Hash

@computation cluster QueensMPI begin

    using MPI
    using StaticArrays

    MPI.Init()

    @unit master begin

        cutoff_depth = 2

        function queens(size; cutoff_depth = 5)

            size += 1

            local_visited, local_permutation = Main.createArrays(Val(size))

            queens(size, 1, local_visited, local_permutation)
        
        end #caller

        function queens(size, cutoff_depth_initial, local_visited, local_permutation) 

            (subproblems, partial_tree_size) = Main.queens_partial_search(cutoff_depth_initial, cutoff_depth_initial + 1, cutoff_depth_initial + cutoff_depth, size, local_visited, local_permutation)
            number_of_subproblems = length(subproblems) #+ number_of_subproblems_initial

            @info "QUEENS MPI $size $cutoff_depth $number_of_subproblems"

            num_workers = length(topology[:worker])
            proc_tree_size = zeros(Int64, num_workers)
            proc_num_sols  = zeros(Int64, num_workers)
            proc_load = fill(div(number_of_subproblems, num_workers), num_workers)
            proc_load[num_workers] += mod(number_of_subproblems, num_workers)
        
            result = Dict()
        
            idx = 1 
        
            @info length(subproblems)
        
            for i in topology[:worker]        
                local local_load = proc_load[i]
        
                local_subproblems = subproblems[idx:(idx + local_load - 1)]
                idx += local_load
        
                MPI.send(false, MPI.COMM_WORLD; dest = i, tag = 9)

                args = (size, cutoff_depth_initial + cutoff_depth, local_subproblems)
                MPI.send(args, MPI.COMM_WORLD; dest=topology[:worker][i], tag=1)
            end
        
            for i in topology[:worker]
                result[i] = MPI.recv(MPI.COMM_WORLD; source = topology[:worker][i], tag=2)
                ns, ts = fetch(result[i])
                proc_num_sols[i]  += ns
                proc_tree_size[i] += ts
            end
        
            number_of_solutions = sum(proc_num_sols)
            tree_size = sum(proc_tree_size) + partial_tree_size
        
            return number_of_solutions, tree_size
        
        end #caller

        function finish()
            @info "CALL FINISH $(topology[:worker])"
            for i in topology[:worker]
               MPI.send(true, MPI.COMM_WORLD; dest = i, tag = 9)
            end
        end
    end
    
    @unit parallel count=N worker begin

        @inner QueensManycore

        termination_flag = Ref{Bool}(false)

        master_rank = topology[:master][1]

        termination_flag[] = MPI.recv(MPI.COMM_WORLD; source=master_rank, tag = 9)
        while (!termination_flag[])
            (size, cutoff_depth, subproblems) = MPI.recv(MPI.COMM_WORLD; source=master_rank, tag=1)

            number_of_solutions = 0
            tree_size = 0
            for (local_visited, local_permutation) in subproblems                 
                ns, ts = QueensManycore.queens(size, cutoff_depth, local_visited, local_permutation)
                @info "+++++++++++++++++++++++ $ns $ts"
                number_of_solutions += ns
                tree_size += ts
            end
            res = (number_of_solutions, tree_size)

            MPI.send(res, MPI.COMM_WORLD; dest = master_rank, tag = 2)
            termination_flag[] = MPI.recv(MPI.COMM_WORLD; source=master_rank, tag = 9)
        end
    end
    
end