using Hash

@computation manycore Q begin

    @unit master begin

        function do_something(x)
            @info "Q DO_SOMETHING $x at master !"
        end
        
    end

    @unit parallel count = T worker begin

    end

end


