# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

myrank(::Type{MessagePassing}) = MPI.Comm_rank(MPI.COMM_WORLD) 

function unit_macro_result(level::Type{MessagePassing}, ::Val{is_level_top}, ::Val{uname}, unit_uids, flag, block#=, global_uids, local_uids=#) where {uname, is_level_top}
    @info "2 **************************** $uname $level $unit_uids $(myrank(level))"
    idx = indexin(myrank(level), unit_uids)
    result = if !isnothing(idx[1])
                pushfirst!(block.args, Expr(:(=), :unit, Expr(:call, :Symbol, string(uname))))  #    :(unit_name = Symbol($uname)))              # unit name
                pushfirst!(block.args, :(unit_idx = $(idx[1])))              # unit_idx
                push!(block.args, :(Hash.reset_enclosing_unit())) 
                @info "$(myrank(level)): ++++++++++++++++++ UNIT $uname of $(current_component()) at level $level --- unit_idx = $(idx[1])"
                block
            else
                Hash.reset_enclosing_unit()
                @info "$(myrank(level)): ------------------ UNIT $uname of $(current_component()) at level $level --- unit_idx = $(idx[1])"
                nothing
            end
    return result
end