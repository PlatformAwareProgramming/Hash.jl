# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

abstract type Cluster <: AnyLevel end
level_type(::Val{:cluster}) = Cluster
level_depth(::Type{Cluster}) = 1

start_index(::Type{Cluster}) = 0

function placement_expr(::Type{Cluster}, expr)
    size = MPI.Comm_size(MPI.COMM_WORLD)
    expr_result = :(let N = $(size-1); $expr end)
    return expr_result
end

function determine_current_args(level::Type{Cluster}, ::Val{id}, ::Val{true}, block) where id
 
    units = collect_units(level, block)

    @info units

    total_count[], ts = distribute_units(units)

    l = ""
    for i in 0:length(ts)-1
        l = l * "$(ts[i+1])\n"
    end

    current_args[] = l
    return l
end

function determine_current_args(::Type{Cluster}, ::Val{id}, ::Val{false}, block) where id
    nothing
end
