using Hash

@computation module Q

    @unit module main

        function do_something(x)
            @info "Q DO_SOMETHING $x at main !"
        end
        
    end

    @unit module worker

    end

end


