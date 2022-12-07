using Hash

@computation manycore module R

    @unit parallel module x

        function go(unit_idx)
            @info "GO X... $unit_idx"
        end

    end

    @unit parallel module y

        function go(unit_idx)
            @info "GO Y... $unit_idx"
        end

    end
end