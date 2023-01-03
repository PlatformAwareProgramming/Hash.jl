
function slice_macro(::Type{Manycore}, s)

    @assert s.head == :. && length(s.args) == 2

    result = Expr(:import, Expr(:as, Expr(:., :., s.args[1]), unquotenode(s.args[2])))

    @info "&&&&&& SLICE mc: $result"

    return result
end

function slice_macro(::Type{Manycore}, s, as, b)

    @assert s.head == :. && length(s.args) == 2

    result = Expr(:import, Expr(as, Expr(:., :., s.args[1]), b))

    @info "&&&&&& SLICE mc: $result"

    return result

end

