# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

macro unit(uname, block, uids)

    @assert block.head == :block

    return unit_macro(current_level[], true, uname, block, uids)

end

macro unit(modifier, uname, block, uids)

    @assert block.head == :block
    
    @info "unit $uname $uids rank=$(myrank(current_level[]))"

    return unit_macro(current_level[], true, uname, block, uids)

end

macro unit(modifier, count, uname, block, uids)
    
    @assert block.head == :block
    @assert count.head == :(=) && count.args[1] == :count

    @info "unit $uname $uids rank=$(myrank(current_level[]))"

    return unit_macro(current_level[], true, uname, block, uids)
end

function unit_macro(level, flag, uname, block, unit_uids)

    @assert block.head == :block    
    
    enclosing_unit[] = uname

    level_parent = level_dict[][parent_component()]
    is_level_top = level_parent != level

    expr = unit_macro_result(level, Val(is_level_top), Val(uname), unit_uids, flag, block#=, global_uids, local_uids=#) 

    return esc(expr)
end






