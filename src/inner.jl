# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function inner_component(c)    
    current_args[] = args_dict[][c]     
    current_level[] = level_dict[][c]
    cname = "$(string(c)).jl"
    @info "CURRENT ARGS for $cname is $(current_args[])"
    return esc(:(include($cname)))        
end

macro inner(c)    
    inner_component(c)
end
