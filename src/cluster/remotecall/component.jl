# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

abstract type RemoteCall <: AnyLevel end
level_type(::Val{:remotecall}) = RemoteCall
level_depth(::Type{RemoteCall}) = 1

start_index(::Type{RemoteCall}) = 1

function placement_expr(::Type{RemoteCall}, expr)
    nworkers = Distributed.nworkers()
    return :(let W = $nworkers; $expr end)
end

function determine_current_args(level::Type{RemoteCall}, ::Val{id}, ::Val{true}, block) where id

    units = collect_units(level, block)

    total_count[], ts = distribute_units(units)

    l = ""
    for i in 0:length(ts)-1
        l = l * "$(ts[i+1])\n"
    end

    current_args[] = l
    return l
end

function determine_current_args(::Type{RemoteCall}, ::Val{id}, ::Val{false}, block) where id 
    nothing
end