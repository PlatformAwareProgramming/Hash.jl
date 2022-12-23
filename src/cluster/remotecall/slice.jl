

function slice_macro(::Type{RemoteCall}, s)

    #result = Expr(:import, Expr(:., :., s.args[1]))
    @assert s.head == :. && length(s.args) == 2

    result = Expr(:import, Expr(:as, Expr(:., :., s.args[1]), unquotenode(s.args[2])))

    @info "&&&&&& SLICE rc: $result"

    return result
end

function slice_macro(::Type{RemoteCall}, s, as, b)

    @assert s.head == :. && length(s.args) == 2

    result = Expr(:import, Expr(as, Expr(:., :., s.args[1]), b))

    @info "&&&&&& SLICE rc: $result"

    return result

end