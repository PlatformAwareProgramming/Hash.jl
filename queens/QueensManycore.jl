@computation manycore QueensManycore begin
    
    using CUDA

    num_threads = length(Hash.getTopology()[:worker])

    fork = Ref(Dict(i => Threads.Condition() for i in 1:num_threads))
    fork_flag = Ref(Dict(i => false for i in 1:num_threads))
    join = Ref(Dict(i => Threads.Condition() for i in 1:num_threads))
    join_flag = Ref(Dict(i => false for i in 1:num_threads))

    size = Ref{Int}()
    cutoff_depth = Ref{Int}()
    number_of_subproblems = Ref{Int}()
    subproblems = Ref{Any}()
    thread_load = Ref{Any}()
    thread_tree_size = Ref{Vector{Int64}}(zeros(Int64, num_threads))
    thread_num_sols  = Ref{Vector{Int64}}(zeros(Int64, num_threads))

    @unit master begin        

        function get_cpu_load(percent::Float64, num_subproblems::Int64)::Int64
            return floor(Int64,num_subproblems*percent)
        end

        function get_load_each_gpu(gpu_load, num_gpus, device_load)

            for device in 1:num_gpus
                device_load[device] = floor(Int64, gpu_load/num_gpus)
                if(device == num_gpus)
                    device_load[device]+= gpu_load%num_gpus
                end
            end
        
        end 
        
        function get_starting_point_each_gpu(cpu_load::Int64, num_devices, device_load,device_starting_point)
            
            starting_point = cpu_load
            device_starting_point[1] = starting_point + 1
            if(num_devices>1)
                for device in 2:num_devices			
                    device_starting_point[device] = device_starting_point[device-1]+device_load[device-1]
                end
            end
        
        end ###

        function queens(size; cutoff_depth = 5)
        
            size += 1
        
            (subproblems, partial_tree_size) = Main.queens_partial_search(Val(size), cutoff_depth)
        
            number_of_solutions, tree_size = queens(size, cutoff_depth, subproblems) 
            tree_size += partial_tree_size
        
            return number_of_solutions, tree_size
        
        end #caller

        function queens(size, cutoff_depth, subproblems) 

            number_of_subproblems = length(subproblems)

            num_gpus = Int64(length(CUDA.devices()))
        
            tree_each_task = zeros(Int64, num_gpus + 1)
            sols_each_task = zeros(Int64, num_gpus + 1)
        
            cpup = Main.getCpuPortion()
            cpu_load = get_cpu_load(cpup, number_of_subproblems)
            gpu_load = number_of_subproblems - cpu_load
        
            device_load = zeros(Int64, num_gpus)
            device_starting_position = zeros(Int64, num_gpus)
            if gpu_load > 0
                get_load_each_gpu(gpu_load, num_gpus, device_load)
                get_starting_point_each_gpu(cpu_load, num_gpus, device_load, device_starting_position)
            end
        
            @info "Total load: $number_of_subproblems, CPU percent: $(cpup*100)%" 
            @info "CPU load: $cpu_load, Number of threads: $num_threads"
            @info "GPU load: $gpu_load, Number of GPUS: $num_gpus"
            
            if gpu_load > 0
            	for device in 1:num_gpus
            		@info "Device: $device, Load: $(device_load[device]), Start point: $(device_starting_position[device])"
            	end
            end
        
            @sync begin
                if num_gpus > 0 && gpu_load > 0
                    for gpu_dev in 1:num_gpus
                        Threads.@spawn begin
                            device!(gpu_dev-1)
                            # @info "- starting device: $(gpu_dev - 1)"
                            (sols_each_task[gpu_dev],tree_each_task[gpu_dev]) = Main.queens_gpu_caller(size, 
                                                                                                       cutoff_depth,
                                                                                                       device_load[gpu_dev],
                                                                                                       device_starting_position[gpu_dev], 
                                                                                                       subproblems)
                        end
                    end
                end 
                #Threads.@spawn begin
                    if cpu_load > 0 
                        # @info "- starting host on $num_threads threads"
                        (sols_each_task[num_gpus+1],tree_each_task[num_gpus+1]) = queens_worker(size,		
                                                                                                cutoff_depth,
                                                                                                cpu_load,
                                                                                                subproblems) 
                    end
                #end 
            end
            final_tree = sum(tree_each_task)
            final_num_sols = sum(sols_each_task)
        
            return final_num_sols, final_tree               

        end

        function queens_worker(size_param, cutoff_depth_param, number_of_subproblems_param, subproblems_param) 

            #number_of_subproblems_param = length(subproblems_param)
            size[] = size_param
            cutoff_depth[] = cutoff_depth_param
            number_of_subproblems[] = number_of_subproblems_param
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
            mcore_tree_size = sum(thread_tree_size[])

            thread_num_sols[] .= 0
            thread_tree_size[] .= 0
        
            return mcore_number_of_solutions, mcore_tree_size
        
        end #caller        
        
    end
    
    @unit parallel count=T worker begin

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

            for j in 1:local_load        
                s = (local_thread_id - 1) * stride + j
                local_number_of_solutions, local_partial_tree_size = Main.queens_tree_explorer_parallel(Val(size[]), Val(cutoff_depth[]), subproblems[][s][1], subproblems[][s][2])
                thread_tree_size[][local_thread_id] += local_partial_tree_size
                thread_num_sols[][local_thread_id]  += local_number_of_solutions
            end

            lock(join[][unit_idx]) do 
                join_flag[][unit_idx] = true; notify(join[][unit_idx])
            end

        end

    end
    
end