# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

macro inner(c)    
    inner_component(c)
end

function inner_component(c)    
    cname = "$(string(c)).jl"
    @info "CURRENT ARGS for $cname is $(current_args[])"

    return esc(:(include($cname)))
end