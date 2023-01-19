using Hash

@computation manycore GEMM_threads_entry begin

    @info "GEMM_2 # -- topology=$topology"
    @info "GEMM_2 # -- local_topology=$local_topology"

    go1_condition = Ref{Dict{Integer,Bool}}(Dict{Integer,Bool}())
    go1_ = Ref{Dict{Integer,Threads.Condition}}(Dict{Integer,Threads.Condition}())

    go2_condition = Ref{Dict{Integer,Bool}}(Dict{Integer,Bool}())
    go2_ = Ref{Dict{Integer,Threads.Condition}}(Dict{Integer,Threads.Condition}())

    for idx in local_topology[:worker]
        go1_condition[][idx] = false
        go1_[][idx] = Threads.Condition()
        go2_condition[][idx] = false
        go2_[][idx] = Threads.Condition()
    end

    go_caller() = begin
                    for idx in local_topology[:worker]
                        go1_condition[][idx] = true 
                        lock(go1_[][idx]) do 
                            notify(go1_[][idx]) 
                        end 
                    end
                  end
    go_callee(idx) = begin 
                        lock(go1_[][idx]) do 
                            while !go1_condition[][idx]
                                wait(go1_[][idx])
                            end     
                            go1_condition[][idx] = false 
                        end
                      end

    finish_go(idx) = begin 
                        go2_condition[][idx] = true 
                        lock(go2_[][idx]) do 
                            notify(go2_[][idx]) 
                        end 
                     end

    wait_go() = begin 
                  for idx in local_topology[:worker]
                      lock(go2_[][idx]) do 
                         while !go2_condition[][idx]
                             wait(go2_[][idx])
                         end     
                         go2_condition[][idx] = false 
                      end
                  end
                end

    alpha = Ref{Float64}()
    beta = Ref{Float64}()
    a = Ref{Matrix{Float64}}()
    b = Ref{Matrix{Float64}}()
    c = Ref{Matrix{Float64}}()
                

    @unit master begin
    
        @info "GEMM_2 master -- unit_idx=$unit_idx"

        function multiply!(alfa0, beta0, a0, b0, c0)
            alpha[] = alfa0; beta[] = beta0
            a[] = a0; b[] = b0; c[] = c0    
            go_caller()
            wait_go()
        end
    
       #= 
         N = 1000

        aa = ones(N,N)
        bb = ones(N,N)
        cc = zeros(N,N)
        multiply(1.0, 1.0, aa, bb, cc)

        @info c[][Int64(N/2),Int64(N/2)]
        @info c[][1,1]
        @info c[][N,N]
        @info c[][1,N]
        @info c[][N,1]
=#
    end

    @inner GEMM_threads

    @unit parallel count=T worker begin
    
        @info "GEMM_2 worker -- unit_idx=$unit_idx"

        @slice GEMM_threads.gemm 

        while true 
            go_callee(unit_idx)
            gemm.multiply!(unit_idx, alpha[], beta[], a[], b[], c[])
            finish_go(unit_idx)
        end

    end

end
