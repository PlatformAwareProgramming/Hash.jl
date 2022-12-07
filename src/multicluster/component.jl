# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function determine_current_args(::Type{Multicluster}, ::Val{0}, level_transition, block)
    for w in workers()
        @info "send placement 2 to $w"
        @spawnat w calculate_placement(current_args[])
    end
end

function determine_current_args(::Type{Multicluster}, ::Val{id}, level_transition, block) where id 
    nothing
end