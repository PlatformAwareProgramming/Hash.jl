# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

abstract type Multicluster <: AnyLevel end
level_type(::Val{:multicluster}) = Multicluster

start_index(::Type{Multicluster}) = 1

function determine_current_args(::Type{Multicluster}, ::Val{1}, ::Val{true}, block)
    for w in workers()
        @info "send placement $(current_args[]) to $w"
        @spawnat w recv_current_args2(current_args[])
    end
end

function recv_current_args2(c)
    @info "recv_current_args $c"
    current_args[] = c
end

function determine_current_args(::Type{Multicluster}, ::Val{id}, ::Val{lt}, block) where {id, lt}
    nothing
end