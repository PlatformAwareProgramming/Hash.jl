# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function unit_macro(flag, uname, block, global_uids, is_parallel)

    @assert block.head == :block    
    
    @info "unit $uname $global_uids"

    l = Vector()
    for (k,v) in global_uids            
        for j in v 
            push!(l, j)
        end
    end
    
    sort!(l)
    
    d = Dict()
    for i in 1:length(l)
        d[l[i]] = i
    end

    local_uids = Dict()
    for (k,v) in global_uids
        local_uids[k] = Vector()
        for j in v 
            push!(local_uids[k], d[j])
        end
    end
        
    unit_uids = get(global_uids, uname, [])    
    idx = indexin(rank#=Main.myid()=#, unit_uids)
    if (!isnothing(idx[1]))
        insert!(block.args, 1, :(global_topology = $global_uids)) # global_topology
        insert!(block.args, 1, :(local_topology = $local_uids))   # local_topology
        insert!(block.args, 1, :(unit_idx = $(idx[1])))           # unit_idx
        insert!(block.args, 1, Meta.parse("using $(repeat(".",current_level[]*2+1))Hash"))
        return esc(Expr(:module, flag, uname, block))
    else
        return nothing
    end
end

macro unit(mod, uids)

    @assert mod.head == :module

    flag  = mod.args[1]
    uname = mod.args[2]
    block = mod.args[3]

    unit_macro(flag, uname, block, uids, false)

end

macro unit(modifier, mod, uids)

    @assert mod.head == :module
    
    flag  = mod.args[1]
    uname = mod.args[2]
    block = mod.args[3]

    @assert modifier == :parallel || (modifier == :single && haskey(uids,uname) && length(uids[uname]) == 1)

    return unit_macro(flag, uname, block, uids, modifier == :parallel)

end
