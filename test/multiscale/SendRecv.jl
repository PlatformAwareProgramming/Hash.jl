module SendRecv

    module sender

        import ..SendRecv

        function send(x)
            @info "S $x !"
            SendRecv.data[] = x
        end

    end
    
    const data = Ref{Any}(99)       # shared data between units

    module receiver

        import ..SendRecv
        
        function recv()
            @info "R!"
            return SendRecv.data[]
        end

    end

end


#=

module SendRecv

 const data = Ref{Any}(99)       # shared data between units

 @unit sender
    function send(x)
        @info "S $x !"
        SendRecv.data[] = x
    end
 end

 @unit receiver
    function recv()
        @info "R!"
        return SendRecv.data[]
    end
 end

end

=#
