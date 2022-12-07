using Hash

@computation manycore module Q

    @unit module main

        function do_something(x)
            @info "Q DO_SOMETHING $x at main !"
        end
        
    end

    @unit parallel count = C-1 module worker

    end

end


