# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

myrank(::Type{RemoteCall}) = myid() 

function unit_macro_result(level::Type{RemoteCall}, is_level_top, ::Val{uname}, unit_uids, flag, block#=, global_uids, local_uids=#) where {uname}
    @info "1 **************************** $uname $level $unit_uids $(myrank(level))"
    idx = indexin(myrank(level), unit_uids)
    result = if !isnothing(idx[1])
                pushfirst!(block.args, :(unit_idx = $(idx[1])))           # unit_idx
                pushfirst!(block.args, :(using Hash))
                push!(block.args, :(Hash.reset_enclosing_unit()))
                block
            else
                Hash.reset_enclosing_unit()
                nothing
            end
    return result
end
