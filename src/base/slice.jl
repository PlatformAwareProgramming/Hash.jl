# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

macro slice(s)

    ss = split(string(s),".")
    @assert length(ss) in [1,2]

    if length(ss) == 1 
        return esc(Expr(:import, Expr(:.,:., s, :main)))
    else
        return esc(Expr(:import, Expr(:., :., :., s.args[1], unquotenode(s.args[2]))))
    end
end   

macro slice(s, as, b)
    
    ss = split(string(s),".")
    @assert length(ss) in [1,2]

    if length(ss) == 1 
        return esc(Expr(:import, Expr(as, Expr(:., :., s, :main), b)))
    else
        return esc(Expr(:import, Expr(as, Expr(:., :., :., s.args[1], unquotenode(s.args[2])), b)))
    end
end   
