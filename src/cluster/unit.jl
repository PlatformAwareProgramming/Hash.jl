# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function unit_macro_result(level::Type{Cluster}, is_level_top, ::Val{uname}, unit_uids, flag, block, global_uids, local_uids) where {uname}
    @info "2 **************************** $uname $level $unit_uids $(myrank(level))"
    idx = indexin(myrank(level), unit_uids)
    result = if !isnothing(idx[1])
                pushfirst!(block.args, :(global_topology = $global_uids))    # global_topology
                pushfirst!(block.args, :(local_topology = $local_uids))   # local_topology
                pushfirst!(block.args, :(unit_idx = $(idx[1])))           # unit_idx
                pushfirst!(block.args, :(using Hash))
                push!(block.args, :(Hash.reset_enclosing_unit())) 
                #@info "$(myrank(level)): ++++++++++++++++++ UNIT $uname of $(current_component()) at level $level"
                Expr(:module, flag, uname, block)
            else
                Hash.reset_enclosing_unit()
                #@info "$(myrank(level)): ------------------ UNIT $uname of $(current_component()) at level $level"
                nothing
            end
    return result
end