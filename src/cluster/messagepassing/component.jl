# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

abstract type MessagePassing <: Cluster end
level_type(::Val{:messagepassing}) = MessagePassing

start_index(::Type{MessagePassing}) = 0

function placement_expr(::Type{MessagePassing}, expr)
    size = MPI.Comm_size(MPI.COMM_WORLD)
    expr_result = :(let N = $(size-1); $expr end)
    return expr_result
end

function determine_current_args(level::Type{MessagePassing}, ::Val{id}, ::Val{true}, block) where id
 
    units = collect_units(level, block)

    total_count[], ts = distribute_units(units)

    l = ""
    for i in 0:length(ts)-1
        l = l * "$(ts[i+1])\n"
    end

    current_args[] = l
    return l
end


function determine_current_args(::Type{MessagePassing}, ::Val{id}, ::Val{false}, block) where id
    nothing
end
