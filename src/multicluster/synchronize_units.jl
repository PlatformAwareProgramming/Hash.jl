

ready_unit = Dict()
ready_unit_flag = Dict()

function check_ready_unit()
    if !haskey(ready_unit, current_component())
        ready_unit[current_component()] = Dict(i => Dict(j => Threads.Condition() for j in unit_topology[current_component()][i]) for i in keys(unit_topology[current_component()]))
        ready_unit_flag[current_component()] = Dict(i => Dict(i => false for i in unit_topology[current_component()][i]) for i in keys(unit_topology[current_component()]))
    end
end

function notify_unit_recv(unit_source, unit_source_idx)
    check_ready_unit()
    wid = unit_topology[current_component()][unit_source][unit_source_idx]
    lock(ready_unit[current_component()][unit_source][wid]) do 
        ready_unit_flag[current_component()][unit_source][wid] = true
        notify(ready_unit[current_component()][unit_source][wid])          
    end
end 

function notify_unit(unit_source::Symbol, unit_idx::Int, unit_target::Symbol; delay_time = -1)
    for idx in unit_topology[current_component()][unit_target]
        notify_unit(unit_source, unit_idx, idx; delay_time = delay_time)
    end
end

function notify_unit(unit_source::Symbol, unit_target::Symbol; delay_time = -1)
    notify_unit(unit_source, 1, unit_target; delay_time = delay_time)
end

function notify_unit(unit_source::Symbol, unit_idx::Int, unit_target::Symbol, i::Int; delay_time = -1)
    notify_unit(unit_source, unit_idx, unit_topology[current_component()][unit_target][i]; delay_time = delay_time)
end

function notify_unit(unit_source::Symbol, unit_target::Symbol, i::Int; delay_time = -1)
    notify_unit(unit_source, 1, unit_topology[current_component()][unit_target][i]; delay_time = delay_time)
end

function notify_unit(unit_source::Symbol, unit_idx::Int, idx::Int; delay_time = -1)

    while !(idx in procs())
        sleep(0.5)
    end
    if (delay_time > 0) sleep(delay_time) end
    unit_source_string = string(unit_source)
    @async @remotecall_fetch idx Hash.notify_unit_recv(Symbol($unit_source_string), $unit_idx)

end

function notify_unit(unit_source, idx::Int; delay_time = -1)
    notify_unit(unit_source, 1, idx; delay_time = delay_time)
end

function wait_unit(unit_id, unit_idx)
    check_ready_unit()
    lock(ready_unit[current_component()][unit_id][unit_idx]) do
        while !ready_unit_flag[current_component()][unit_id][unit_idx] 
            wait(ready_unit[current_component()][unit_id][unit_idx])
        end
        ready_unit_flag[current_component()][unit_id][unit_idx] = false
    end

end

function wait_unit(unit_id)
    for i in unit_topology[current_component()][unit_id]
        wait_unit(unit_id, i)
    end
end

