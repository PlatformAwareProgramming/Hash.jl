# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

macro unit(uname, block, uids)

    @assert block.head == :block

    #@assert haskey(uids,uname) && length(uids[uname]) == 1

    return unit_macro(current_level[], true, uname, block, uids)

end

macro unit(modifier, uname, block, uids)

    @assert block.head == :block
    
    @info "unit $uname $uids rank=$(myrank(current_level[]))"

    #@assert modifier == :parallel || (modifier == :single && haskey(uids,uname) && length(uids[uname]) == 1)

    return unit_macro(current_level[], true, uname, block, uids)

end

macro unit(modifier, count, uname, block, uids)

    @assert block.head == :block
    @assert count.head == :(=) && count.args[1] == :count

    @info "unit $uname $uids rank=$(myrank(current_level[]))"

    #@assert modifier == :parallel || (modifier == :single && haskey(uids,uname) && length(uids[uname]) == 1)

    return unit_macro(current_level[], true, uname, block, uids)

end



function unit_macro(level, flag, uname, block, unit_uids)

    @assert block.head == :block    
    
    enclosing_unit[] = uname

    level_parent = level_dict[][parent_component()]
    is_level_top = level_parent != level

#    local_uids = calculate_local_uids(global_uids)
        
#    unit_uids = get(global_uids, uname, [])     

    expr = unit_macro_result(level, Val(is_level_top), Val(uname), unit_uids, flag, block#=, global_uids, local_uids=#) 

    #@info expr
    return esc(expr)
end






