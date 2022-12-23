using Hash

@computation manycore P begin

    @inner R

    @unit master begin

        function do_something(z)
            @info "DO_SOMETHING $z at master !"
        end
        
    end

    state = 0

    @unit parallel count = C athostA begin

        @slice R.x as xxx

        @info "()()()()()() athostA $(P.state)"
        
        xxx.go(unit_idx)

    end

    @unit parallel count = C athostB begin

        @slice R.y 

        @info "()()()()()() athostB $(P.state)"
        
        y.go(unit_idx)

    end

end

