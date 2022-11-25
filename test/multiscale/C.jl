module C

    module main

    end


    module worker

        include("P.jl"); import .P as do_p   # renaming the slice
 
        function process(x)
            @info "PROCESS $x !"
            do_p.do_something(0)
        end

    end

end
