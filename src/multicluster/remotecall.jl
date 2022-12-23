

macro remotecall(i, call)
    esc(:(Distributed.remotecall(Core.eval, $i, Main, $(Expr(:quote, call)))))
end

macro remotecall_fetch(i, call)
    esc(:(Distributed.remotecall_fetch(Core.eval, $i, Main, $(Expr(:quote, call)))))
end