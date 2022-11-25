# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

macro slice(s)
    return esc(Expr(:import, Expr(:., :., :., s.args[1], unquotenode(s.args[2]))))
end   

macro slice(s,as,b)
    return esc(Expr(:import, Expr(as, Expr(:., :., :., s.args[1], unquotenode(s.args[2])), b)))
end   
