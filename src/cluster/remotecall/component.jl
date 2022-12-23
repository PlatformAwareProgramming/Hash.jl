# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

abstract type RemoteCall <: Cluster end
level_type(::Val{:remotecall}) = RemoteCall

start_index(::Type{RemoteCall}) = 1

function placement_expr(::Type{RemoteCall}, expr)
    nprocs = nworkers()
    return :(let P = $nprocs; $expr end)
end

function determine_current_args(::Type{RemoteCall}, ::Val{1}, ::Val{true}, block)
    for w in workers()
        @info "send placement $(current_args[]) to $w"
        @spawnat w recv_current_args(current_args[])
    end
end

function determine_current_args(::Type{RemoteCall}, ::Val{1}, ::Val{false}, block)
    nothing
end

function recv_current_args(c)
    @info "recv_current_args $c"
    current_args[] = c
end

function determine_current_args(::Type{RemoteCall}, ::Val{id}, level_transition, block) where id 
    nothing
end