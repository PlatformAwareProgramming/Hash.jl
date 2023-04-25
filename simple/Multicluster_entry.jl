using Hash

@computation multicluster Multicluster_entry begin

    using Distributed
 
    @unit master begin

        function go()
            Threads.@threads for sidx in topology[:worker]
                @remotecall_fetch sidx Multicluster_entry.perform()   
            end
        end

    end

    # source and worker are supposedly in the same network domain (one-by-one correspondence)

    @unit parallel worker begin

        function touch()
            @info "TOUCHED"
        end

        function perform()

            my_idx = topology[:worker][unit_idx]
            for idx in topology[:worker] 
                if my_idx < idx
                    @info "Hi from $my_idx to $idx !"
                    @remotecall_fetch idx Multicluster_entry.touch()  
                end
            end

        end

    end

end