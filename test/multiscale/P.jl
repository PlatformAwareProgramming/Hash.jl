
using Hash

@computation module P

    @unit module main 

        function do_something(x)
            @info "DO_SOMETHING $x at main !"
        end
        
    end

    @unit module worker

    end

end

