# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

macro datasource(level, mod)
    component_macro(level_type(Val(level)), mod.args[2], mod.args[3], false)
end

macro datasource(mod)
    component_macro(AnyLevel, mod.args[2], mod.args[3], false)
end

macro connector(level, mod)
    component_macro(level_type(Val(level)), mod.args[2], mod.args[3], false)
end

macro connector(mod)
    component_macro(AnyLevel, mod.args[2], mod.args[3], false)
end

macro computation(level, mod)
    component_macro(level_type(Val(level)), mod.args[2], mod.args[3], false)
end

macro computation(mod)
    component_macro(AnyLevel, mod.args[2], mod.args[3], false)
end

macro application(level, mod)
    cname = string(mod.args[2])
    args_dict[]["Main.$cname"] = readlines("placement")
    current_level[] = level_type(Val(level))
    component_macro(current_level[], mod.args[2], mod.args[3], true)
end
    
macro application(mod)
    component_macro(AnyLevel, mod.args[2], mod.args[3], true)
end

function component_macro(level::Type{<:AnyLevel}, cname, block, isapp)

    @assert level <: current_level[]

    is_level_transition = level != current_level[]
    
    current_component_name = is_level_transition ? "$(current_component()).$(enclosing_unit[]).$cname" : "$(current_component()).$cname"
    @info "************************** $current_component_name $is_level_transition $level $(current_level[])"

    saved_enclosing_unit = enclosing_unit[]
    if is_level_transition
        Hash.reset_enclosing_unit()
        current_depth[] = 0
    end

    level_dict[][current_component_name] = level

    pushComponent(string(current_component_name))

    @info "THE depth OF $current_component_name is $(current_depth[]) -- ENCLOSING UNIT $(enclosing_unit[])"

    placement_units(level, Val(myrank(level)), Val(is_level_transition), block)

    ss = collect_slices(block)
    
    for (cname, us) in ss
        l = Vector()
        for (sname, uname) in us
            sname_string = unquotenode(sname)

            for id in placement_inv[][uname]
                push!(l,"$id $sname_string")
            end
        end
        args_dict[][cname] = l
    end 
    
    insert_unit_uids(block)

    if (level == Manycore && is_level_transition)
        pushfirst!(block.args, Meta.parse("function notify_unit_finished() Threads.atomic_add!(wait_unit_threads_counter, 1); if $(Threads.nthreads()) <= wait_unit_threads_counter[] lock(wait_unit_threads[]) do \n notify(wait_unit_threads[]) end end end"))
        pushfirst!(block.args, :(wait_unit_threads_counter = Threads.Atomic{Int}(0)))
        pushfirst!(block.args, :(wait_unit_threads = Ref{Threads.Condition}(Threads.Condition())))
        push!(block.args, Meta.parse("while wait_unit_threads_counter[]<$(Threads.nthreads()) lock(wait_unit_threads[]) do \n wait(wait_unit_threads[]) end end"))
    end

    pushfirst!(block.args, :(using Hash))

    push!(block.args,:(Hash.popComponent()))
    if (is_level_transition)
        push!(block.args, Meta.parse("Hash.enclosing_unit[] = :($saved_enclosing_unit)"))
    end

    #@info Expr(:module, true, cname, block)
    return esc(Expr(:module, true, cname, block))

end

function placement_units(level::Type{<:AnyLevel}, id, level_transition, block)
       
    @info "CALCULATE PLACEMENT 1 $(current_depth[])"

    if current_depth[] == 1 
        determine_current_args(level, id, level_transition, block)
    end
    
    calculate_placement(current_args[]) 

    while !has_placement_flag[]
        wait(has_placement)    
    end

end

function collect_units(block)

    @assert block.head == :block
    
    r = Vector()
    
    for st in block.args
        if (typeof(st) == Expr && st.head == :macrocall && !isempty(st.args) && string(st.args[1]) == "@unit")
            uname = nothing
            modifier = nothing
            placement_expr::Int = -1
            for st2 in st.args[2:length(st.args)]
                if typeof(st2)==Expr && st2.head==:module
                    uname = st2.args[2]
                elseif typeof(st2)==Symbol && st2 in [:single, :parallel]
                    modifier = st2
                elseif (typeof(st2)==Expr && st2.head == :(=) && typeof(st2.args[1])==Symbol && st2.args[1] == :count)
                    expr_n = :(let C = $(Threads.nthreads()); $(st2.args[2]) end)
                    placement_expr = eval(expr_n)
                end
            end
            push!(r, (uname, isnothing(modifier) ? :single : modifier, placement_expr))  
            @info "*#*#*#*#*#*#*#*#*#*#*#*# collected unit $((uname, isnothing(modifier) ? :single : modifier, placement_expr))"
        end
    end
    return r
end

function distribute_units(units, n_threads)
    p = Vector()

    for (uname, modifier, count) in units
        @assert !(modifier == :single && count > 1) && !(modifier == :parallel && count < 0)
        if (modifier == :single || count < 0)
            count = 1
        end
        for i in 1:count
            push!(p, uname)
        end
    end
    return p
end


function calculate_placement(main_placement::AbstractArray{String})

    @info "MAIN PLACEMENT <><><><><><><><><><><><><><><> $main_placement"

    empty!(placement[])
    empty!(placement_inv[])

    for l in main_placement
       v = split(l," ")
       id = parse(Int64,v[1])
       pr = Symbol(v[2])
       placement[][id] = pr           
       w = get(placement_inv[],pr,Vector())
       push!(w,id)
       placement_inv[][pr] = w
    end    
    
    has_placement_flag[] = true
    notify(has_placement)
    
end


function collect_slices(block)

    @assert block.head == :block
    
    r = Dict()
    
    inner_cs = Vector()

    uname = nothing
    for st in block.args
        if (typeof(st) == Expr && st.head == :macrocall && !isempty(st.args) && string(st.args[1]) == "@unit")
           for st2 in st.args[2:length(st.args)]
                if (typeof(st2)==Expr && st2.head==:module)
                    uname = st2.args[2]
                    for st3 in st2.args[3].args
                        if typeof(st3) == Expr && st3.head == :macrocall && !isempty(st3.args) && string(st3.args[1]) == "@slice"
                            for st4 in st3.args[2:length(st3.args)]
                                if typeof(st4) == Expr && st4.head == :.
                                    cname = "$(current_component()).$(st4.args[1])"
                                    sname = st4.args[2] 
                                    l = get(r,cname,Vector())
                                    push!(l,(sname,uname))
                                    r[cname] = l
                                    break                                    
                                elseif typeof(st4) == Symbol
                                    cname = "$(current_component()).$uname.$st4"
                                    sname = :(:main)    
                                    l = get(r,cname,Vector())
                                    push!(l,(sname,uname))
                                    r[cname] = l
                                    break
                                end
                            end
                        end
                    end
                    break
                end
            end
        end
    end
    
    return r
end

function collect_inner_components(block)

    @assert (block.head == :block)
    
    ics = Vector()
    for st in block.args
        if (typeof(st) == Expr && st.head == :macrocall && !isempty(st.args) && string(st.args[1]) in ["@inner"])            
            for st2 in st.args[2:length(st.args)]
                if typeof(st2) == Symbol 
                    push!(ics, st2)
                end
            end
        end
    end
    
    return ics

end

function insert_unit_uids(block)
    
    @assert (block.head == :block)
    
    for st in block.args
        if (typeof(st) == Expr && st.head == :macrocall && !isempty(st.args) && string(st.args[1]) == "@unit")            
            for st2 in st.args[2:length(st.args)]
                if (typeof(st2)==Expr && st2.head==:module)
                    uname = st2.args[2]
                    push!(st.args, copy(placement_inv[]))
                    break
                end
            end
        end
    end
               
end