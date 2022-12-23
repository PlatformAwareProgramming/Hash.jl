# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

macro slice(s)

    result = slice_macro(current_level[], s)

    return esc(result)
end   

macro slice(s, as, b)
    
    result = slice_macro(current_level[], s, as, b)

    return esc(result)
end   
