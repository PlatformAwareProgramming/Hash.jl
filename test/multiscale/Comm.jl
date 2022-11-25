module Comm


    module root

        function collect()
            return [1,2,3]
        end

    end

    module peer

        function send(x)
            @info "send $x"
        end

    end

end
