# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function unit_macro_result(level::Type{<:Manycore}, ::Val{true}, ::Val{:main}, unit_uids, flag, block, global_uids, local_uids)

    @info "0 ============================ main $level unit_uids=$unit_uids global_uids=$global_uids local_uids=$local_uids"

    idx = 0
    pushfirst!(block.args, :(global_topology = $global_uids)) # global_topology
    pushfirst!(block.args, :(local_topology = $local_uids))   # local_topology
    pushfirst!(block.args, :(unit_idx = $idx))                # unit_idx
    pushfirst!(block.args, :(using Hash))
    pushfirst!(block.args, Meta.parse("using ..$(current_component())"))
    push!(block.args, Meta.parse("$(current_component()).notify_unit_finished()"))    
   
    return Expr(:module, flag, :main, block)
end

function unit_macro_result(level::Type{<:Manycore}, ::Val{true}, ::Val{uname}, unit_uids, flag, block, global_uids, local_uids) where {uname}

    @info "1 ============================ $uname $(uname == :main) $level unit_uids=$unit_uids global_uids=$global_uids local_uids=$local_uids"

    unit_threads = Vector()
    
    slices = extract_slices(block.args)

    for idx in unit_uids
        args = Vector(); map(a-> push!(args, a), block.args) 
        push!(args, Meta.parse("$(current_component()).notify_unit_finished()"))    
        pushfirst!(args, :(global_topology = $global_uids)) # global_topology
        pushfirst!(args, :(local_topology = $local_uids))   # local_topology
        pushfirst!(args, :(unit_idx = $idx))                # unit_idx
        push!(unit_threads, Expr(:macrocall, Threads.var"@spawn", nothing, Expr(:block, args...)))
    end

    empty!(block.args)
    push!(block.args, :(using Hash))
    push!(block.args, Meta.parse("using ..$(current_component())"))
    for s in slices
        push!(block.args, s)
    end
    push!(block.args, Expr(:block, unit_threads...))

    return Expr(:module, flag, uname, block)
end

function extract_slices(args)

    slices = Vector()
    idx_slices = Vector()

    i = 1
    for st in args
        if typeof(st) == Expr && st.head == :macrocall && !isempty(st.args) && string(st.args[1]) == "@slice"
            push!(slices, st)
            push!(idx_slices, i)
        end
        i += 1
    end

    for j in idx_slices
        deleteat!(args,j)
    end

    return slices
end


function unit_macro_result(level::Type{<:Manycore}, ::Val{false}, ::Val{uname}, unit_uids, flag, block, global_uids, local_uids) where {uname}

    @info "2 ============================ $uname $level $unit_uids $(myrank(level))"
    
    pushfirst!(block.args, :(global_topology = $global_uids)) # global_topology
    pushfirst!(block.args, :(local_topology = $local_uids))   # local_topology
    pushfirst!(block.args, :(using Hash))
    pushfirst!(block.args, Meta.parse("using ..$(current_component())"))
    
    @info "$(myrank(level)): ++++++++++++++++++ UNIT $uname of $(current_component()) at level $level"
    return Expr(:module, flag, uname, block)

end
