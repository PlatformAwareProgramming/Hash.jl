
function slice_macro(::Type{Manycore}, s)



    #if length(ss) == 1 
    ##    return esc(Expr(:import, Expr(:.,:., s, :main)))
    #else
    #    return esc(Expr(:import, Expr(:., :., :., s.args[1], unquotenode(s.args[2]))))
    #end

    ss = split(string(s),".")
    @assert length(ss) in [1,2]

    if length(ss) == 1 
        result = Expr(:import, Expr(:., :., :., s.args[1]))
    else
        result = Expr(:import, Expr(:., :., :., s.args[1], unquotenode(s.args[2])))
    end

    @info "&&&&&& SLICE mc: $result"

    return result
end

function slice_macro(::Type{Manycore}, s, as, b)

    ss = split(string(s),".")
    @assert length(ss) in [1,2]

    if length(ss) == 1 
        result = Expr(:import, Expr(as, Expr(:., :., :., s.args[1]), b))
    else
        result = Expr(:import, Expr(as, Expr(:., :., :., s.args[1], unquotenode(s.args[2])), b))
    end

    @info "&&&&&& SLICE mc: $result"

    return result

end