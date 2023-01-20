using StaticArrays

@computation manycore QueensManycore begin

    num_threads = length(Hash.getTopology()[:worker])

    fork = Ref(Dict(i => Threads.Condition() for i in 1:num_threads))
    fork_flag = Ref(Dict(i => false for i in 1:num_threads))
    join = Ref(Dict(i => Threads.Condition() for i in 1:num_threads))
    join_flag = Ref(Dict(i => false for i in 1:num_threads))

    size = Ref{Int}()
    current_cutoff_depth = Ref{Int}()
    number_of_subproblems = Ref{Int}()
    subproblems = Ref{Any}()
    thread_load = Ref{Any}()
    thread_tree_size = Ref{Vector{Int64}}(zeros(Int64, num_threads))
    thread_num_sols  = Ref{Vector{Int64}}(zeros(Int64, num_threads))

    @unit master begin        

        cutoff_depth = 2

        function queens(size; cutoff_depth = 5)

            size += 1

            local_visited, local_permutation = Main.createArrays(Val(size))

            queens(size, 1, local_visited, local_permutation)
        
        end #caller

        function queens(size_param, cutoff_depth_initial, local_visited, local_permutation) 

            (subproblems_param, partial_tree_size) = Main.queens_partial_search(cutoff_depth_initial, cutoff_depth_initial + 1, cutoff_depth_initial + cutoff_depth, size_param, local_visited, local_permutation)

            size[] = size_param
            current_cutoff_depth[] = cutoff_depth_initial + cutoff_depth
            number_of_subproblems[] =  length(subproblems) #+ number_of_subproblems_initial
            subproblems[] = subproblems_param

            thread_load[] = fill(div(number_of_subproblems[], num_threads), num_threads)
            thread_load[][num_threads] += mod(number_of_subproblems[], num_threads)
        
            for i in 1:num_threads
                lock(fork[][i]) do 
                    fork_flag[][i] = true; notify(fork[][i])
                end
            end

            for i in 1:num_threads                       
                lock(join[][i]) do 
                   while !(join_flag[][i]) 
                        wait(join[][i]) 
                   end
                   join_flag[][i] = false
                end
            end

            mcore_number_of_solutions = sum(thread_num_sols[])
            mcore_tree_size = sum(thread_tree_size[]) + partial_tree_size
        
            return mcore_number_of_solutions, mcore_tree_size
        
        end #caller        
        
    end
    
    @unit parallel count=T worker begin
        @info "unit_idx=$unit_idx"

        local_thread_id = unit_idx

        while true

            lock(fork[][unit_idx]) do 
                while !(fork_flag[][unit_idx])
                    wait(fork[][unit_idx]) 
                end
                fork_flag[][unit_idx] = false
            end

            local_load = thread_load[][local_thread_id]
            stride = div(number_of_subproblems[], length(topology[:worker]))

            @info "!!!!!!!!!! $local_load"
            for j in 1:local_load        
                s = (local_thread_id - 1) * stride + j
                @info "%%%%%%%%%%%%%%%%%%%%%%%%% $(current_cutoff_depth[]), $(size[]) 1"
                local_number_of_solutions, local_partial_tree_size = Main.queens_tree_explorer_parallel(current_cutoff_depth[] + 1, current_cutoff_depth[] + 1, size[] + 1, size[], subproblems[][s][1], subproblems[][s][2])
                @info "%%%%%%%%%%%%%%%%%%%%%%%%% $(current_cutoff_depth[]), $(size[]) 2"
                thread_tree_size[][local_thread_id] += local_partial_tree_size
                thread_num_sols[][local_thread_id]  += local_number_of_solutions
            end

            lock(join[][unit_idx]) do 
                join_flag[][unit_idx] = true; notify(join[][unit_idx])
            end

        end

    end
    
end