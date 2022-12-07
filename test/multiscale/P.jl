using Hash

@computation manycore module P

    @inner R

    @unit module main 

        function do_something(z)
            @info "DO_SOMETHING $z at main !"
        end
        
    end

    state = 0

    @unit parallel count = C-1  module athostA

        @slice R.x

        @info P.state
        
        x.go(unit_idx)

    end

    @unit parallel count = C-1 module athostB

        @slice R.y 

        @info P.state

        y.go(unit_idx)

    end

end

