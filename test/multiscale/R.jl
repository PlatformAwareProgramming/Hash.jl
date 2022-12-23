using Hash

@computation manycore R begin

    state = Ref{Vector}(Vector())

    trava = Threads.ReentrantLock()

    @unit parallel x begin

        function go(unit_idx)
            @info "GO X... begin"
            lock(R.trava) do
                push!(R.state[], unit_idx)
            end
            @info "GO X... $(R.state[])"
        end

    end

    @unit parallel y begin

        function go(unit_idx)
            @info "GO Y... begin"
            lock(R.trava) do
               push!(R.state[], unit_idx) 
            end 
            @info "GO Y... $(R.state[])"
        end

    end
end