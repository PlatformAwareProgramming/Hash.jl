

function slice_macro(::Type{Multicluster}, s)

    #result = Expr(:import, Expr(:., :., s.args[1]))
    @assert s.head == :. && length(s.args) == 2

    result = Expr(:import, Expr(:as, Expr(:., :., s.args[1]), unquotenode(s.args[2])))

    return result
end

function slice_macro(::Type{Multicluster}, s, as, b)

    @assert s.head == :. && length(s.args) == 2

    result = Expr(:import, Expr(as, Expr(:., :., s.args[1]), b))

    return result

end