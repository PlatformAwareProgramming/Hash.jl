

function slice_macro(::Type{MessagePassing}, s)

    #result = Expr(:import, Expr(:., :., s.args[1]))
    @assert s.head == :. && length(s.args) == 2

    result = Expr(:import, Expr(:as, Expr(:., :., s.args[1]), unquotenode(s.args[2])))

    @info "&&&&&& SLICE mp: $result"

    return result
end

function slice_macro(::Type{MessagePassing}, s, as, b)

    @assert s.head == :. && length(s.args) == 2

    result = Expr(:import, Expr(as, Expr(:., :., s.args[1]), b))

    @info "&&&&&& SLICE mp: $result"

    return result

end