# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

macro datasource(level, cname, block)
    component_macro(level_type(Val(level)), cname, block)
end

macro datasource(cname, block)
    component_macro(AnyLevel, cname, block)
end

macro connector(level, cname, block)
    component_macro(level_type(Val(level)), cname, block)
end

macro connector(cname, block)
    component_macro(AnyLevel, cname, block)
end

macro computation(level, cname, block)
    component_macro(level_type(Val(level)), cname, block)
end

macro computation(cname, block)
    component_macro(AnyLevel, cname, block)
end

saved_enclosing_unit = Ref{Any}()

function component_macro(level::Type{<:AnyLevel}, cname, block)

    if (isempty(args_dict[]))
        args_dict[]["Main"] = ""
        args_dict[]["Main.$cname"] = ""
        level_dict[]["Main"] = current_level[]  
    end

    is_level_transition = level != current_level[]
    
    current_component_name = "$(current_component()).$cname"
    @info "************************** $current_component_name $is_level_transition $level $(current_level[])"

    saved_enclosing_unit[] = enclosing_unit[]
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
        l = ""
        for (sname, uname) in us
            sname_string = unquotenode(sname)
            @info placement_inv[]
            ids = placement_inv[][uname]
            for id in ids
                l = l * "$id $sname_string\n"
            end
        end
        args_dict[][cname] = l
    end
    
    insert_unit_uids(block)

    insertAdditionalStatements(level, Val(is_level_transition), block)

    @info "component macro end................ $cname $(typeof(cname))"

   # if (cname == :GEMM_mpi_entry)
   #     @info Expr(:module, true, cname, block)
  #  end
    return esc(Expr(:module, true, cname, block))

end

function calculate_local_uids(global_uids)
    l = Vector()
    for (k,v) in global_uids            
        for j in v 
            push!(l, j)
        end
    end
    
    sort!(l)
    
    d = Dict()
    for i in 1:length(l)
        d[l[i]] = i-1
    end

    local_uids = Dict()
    for (k,v) in global_uids
        local_uids[k] = Vector()
        for j in v 
            push!(local_uids[k], d[j])
        end
    end

    return local_uids
end


function insertAdditionalStatements(::Type{<:AnyLevel}, ::Val{true}, block)
    global_uids = placement_inv[]
    local_uids = calculate_local_uids(global_uids)

    pushfirst!(block.args, :(local_topology = copy($local_uids)))   # local_topology
    pushfirst!(block.args, :(topology = copy($global_uids)))        # topology
    pushfirst!(block.args, :(using Hash))
    push!(block.args,:(Hash.popComponent()))
    push!(block.args, Meta.parse("Hash.enclosing_unit[] = :($(saved_enclosing_unit[]))"))
end

function insertAdditionalStatements(::Type{<:AnyLevel}, ::Val{false}, block)
    global_uids = placement_inv[]
    local_uids = calculate_local_uids(global_uids)

    pushfirst!(block.args, :(local_topology = $local_uids))   # local_topology
    pushfirst!(block.args, :(topology = $global_uids)) # topology
    pushfirst!(block.args, :(using Hash))
    push!(block.args,:(Hash.popComponent()))
end

function placement_units(level::Type{<:AnyLevel}, id, level_transition, block)
       
    determine_current_args(level, id, level_transition, block)
    
    calculate_placement(level, current_args[]) 

    lock(has_placement) do
        while !has_placement_flag[]
            wait(has_placement)    
        end
    end

end

function collect_units(level::Type{<:AnyLevel}, block)

    @assert block.head == :block
    
    r = Vector()
    
    for st in block.args
        if (typeof(st) == Expr && st.head == :macrocall && !isempty(st.args) && string(st.args[1]) == "@unit")
            l = length(st.args)
            unit_count::Int = -1
            if l==4
                modifier = :single
                uname = st.args[3]
            elseif l==5
                modifier = st.args[3]
                uname = st.args[4]
            elseif l==6
                modifier = st.args[3]
                expr_n = placement_expr(level, st.args[4])
                unit_count = eval(expr_n)
                uname = st.args[5]
                @assert(modifier == :parallel)
            else
                modifier = nothing
                uname = nothing
            end
            push!(r, (uname, modifier, unit_count))  
        end
    end
    return r
end


function distribute_units(units)

    p = Vector()

    total_count = 0

    for (uname, modifier, count) in units
        @assert !(modifier == :single && count > 1) && !(modifier == :parallel && count < 0)
        if (modifier == :single || count < 0)
            count = 1
        end
        for i in 1:count
            push!(p, uname)
        end
        total_count += count
    end
    return (total_count, p)

end

function calculate_placement(level::Type{<:AnyLevel}, placement_string::String)

    main_placement = split(placement_string, "\n")
    
    empty!(placement_inv[])

    id_count = start_index(level)
    for l in main_placement
        if l != "" 
            v = split(l, " ")
            if length(v) == 2
               id = parse(Int64,v[1])    
               pr = Symbol(v[2])
            elseif (length(v) == 1)
               id = id_count
               pr = Symbol(l)
            end
            w = get(placement_inv[], pr, Vector())
            push!(w, id)
            placement_inv[][pr] = w
            id_count += 1
        end 
     end    
 
    has_placement_flag[] = true

    lock(has_placement) do
        notify(has_placement)
    end
    
end


function collect_slices(block)

    @assert block.head == :block
    
    r = Dict()

    uname = nothing
    for st in block.args
        if (typeof(st) == Expr && st.head == :macrocall && !isempty(st.args) && string(st.args[1]) == "@unit")
            l = length(st.args)
            if l==4
                uname = st.args[3]
                block = st.args[4]
            elseif l==5
                uname = st.args[4]
                block = st.args[5]
            elseif l==6
                uname = st.args[5]
                block = st.args[6]
            end
            @assert(block.head == :block)
            for st3 in block.args
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
                            cname = "$(current_component()).$st4"
                            sname = :(:master)    
                            l = get(r,cname,Vector())
                            deleteat!(l,findall(x->x==(sname,uname),l)) # remove (:master,???) entries inserted in @inner declarations inside units
                            push!(l,(sname,uname))
                            r[cname] = l
                            break
                        end
                    end
                elseif typeof(st3) == Expr && st3.head == :macrocall && !isempty(st3.args) && string(st3.args[1]) == "@inner"
                    for st4 in st3.args[2:length(st3.args)]
                        if typeof(st4) == Symbol
                            cname = "$(current_component()).$st4"
                            sname = :(:master)    
                            l = get(r,cname,Vector())
                            push!(l,(sname,uname))
                            r[cname] = l
                            break
                        end
                    end
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
            l = length(st.args)
            if l==4
                uname = st.args[3]
            elseif l==5
                uname = st.args[4]
            elseif l==6
                uname = st.args[5]
            end
            push!(st.args, copy(get(placement_inv[], uname, [])))
        end
    end
               
end