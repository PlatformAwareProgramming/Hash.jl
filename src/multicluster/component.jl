# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

abstract type Multicluster <: AnyLevel end
level_type(::Val{:multicluster}) = Multicluster
level_depth(::Type{Multicluster}) = 0

start_index(::Type{Multicluster}) = 1

function determine_current_args(::Type{Multicluster}, ::Val{id}, ::Val{true}, block) where id
    @info "determine_current_args 000"
    l = read("placement", String)
    current_args[] = l
    return current_args
end

function determine_current_args(::Type{Multicluster}, ::Val{id}, ::Val{lt}, block) where {id, lt}
    nothing
end