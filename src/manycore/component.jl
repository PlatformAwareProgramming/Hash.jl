
# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function determine_current_args(::Type{Manycore}, id, ::Val{true}, block) 

    units = collect_units(block)

    ts = distribute_units(units, Threads.nthreads())

    for i in 0:length(ts)-1
        push!(current_args[], "$i $(ts[i+1])")
    end

end

function determine_current_args(::Type{Manycore}, id, ::Val{false}, block)
    nothing
end