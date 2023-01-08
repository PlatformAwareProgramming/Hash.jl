
using Hash

@application multicluster TestMulticluster begin
    
    using Distributed

    @unit master begin

        @info "master"

        @info topology[:workerA]

        for i in topology[:workerA]
            rr = @remotecall_fetch i TestMulticluster.do_work()
            #rr = fetch(r)
            @info "res = $rr"
        end
        
    end

    @unit parallel workerA begin

        @inner TestClusterA

        function do_work() 
            r = TestClusterA.perform()
            @show r
            return r
        end
       
    end


end
