@computation manycore QueensManycore begin

    @unit master begin
    
        function queens(size; cutoff_depth = 5)

            size += 1
        
            (subproblems, number_of_subproblems, partial_tree_size) = queens_partial_search(Val(size), cutoff_depth)
        
            number_of_solutions, tree_size = queens(size, cutoff_depth, number_of_subproblems, subproblems) 
            tree_size += partial_tree_size
        
            return number_of_solutions, tree_size
        
        end #caller
        
        function queens(size, cutoff_depth, number_of_subproblems, subproblems)
        
            num_gpus = Int64(length(CUDA.devices()))
            num_threads = Threads.nthreads()
        
            tree_each_task = zeros(Int64, num_gpus + 1)
            sols_each_task = zeros(Int64, num_gpus + 1)
        
            cpup = getCpuPortion()
            cpu_load = get_cpu_load(cpup, number_of_subproblems)
            gpu_load = number_of_subproblems - cpu_load
        
            device_load = zeros(Int64, num_gpus)
            device_starting_position = zeros(Int64, num_gpus)
            if gpu_load > 0
                get_load_each_gpu(gpu_load, num_gpus, device_load)
                get_starting_point_each_gpu(cpu_load, num_gpus, device_load, device_starting_position)
            end
        
            #@info "Total load: $number_of_subproblems, CPU percent: $(cpup*100)%" 
            #@info "CPU load: $cpu_load, Number of threads: $num_threads"
            #@info "GPU load: $gpu_load, Number of GPUS: $num_gpus"
            
            #if gpu_load > 0
            #	for device in 1:num_gpus
            #		@info "Device: $device, Load: $(device_load[device]), Start point: $(device_starting_position[device])"
            #	end
            #end
        
            @sync begin
                if num_gpus > 0 && gpu_load > 0
                    for gpu_dev in 1:num_gpus
                        Threads.@spawn begin
                            device!(gpu_dev-1)
                            # @info "- starting device: $(gpu_dev - 1)"
                            (sols_each_task[gpu_dev],tree_each_task[gpu_dev]) = queens_gpu_caller(size, 
                                                                                                  cutoff_depth, 																						 
                                                                                                  device_load[gpu_dev],
                                                                                                  device_starting_position[gpu_dev], 
                                                                                                  subproblems)
                        end
                    end
                end 
                Threads.@spawn begin
                    if cpu_load > 0 
                        # @info "- starting host on $num_threads threads"
                        (sols_each_task[num_gpus+1],tree_each_task[num_gpus+1]) = queens_mcore_caller(size,				                                                                            
                                                                                                      cpu_load,
                                                                                                      subproblems) 
                    end
                end 
            end
            final_tree = sum(tree_each_task)
            final_num_sols = sum(sols_each_task)
        
            return final_num_sols, final_tree
        end
        
        
    end
    
    @unit parallel worker begin
    
    end
    
end