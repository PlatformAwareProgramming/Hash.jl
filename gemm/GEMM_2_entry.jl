using Hash

@application manycore GEMM_2_entry begin

    alpha = Ref{Float64}()
    beta = Ref{Float64}()
    a = Ref{Matrix{Float64}}()
    b = Ref{Matrix{Float64}}()
    c = Ref{Matrix{Float64}}()

    go1_condition = Ref{Bool}(false)
    go1_ = Ref{Threads.Condition}(Threads.Condition())

    go2_condition = Ref{Bool}(false)
    go2_ = Ref{Threads.Condition}(Threads.Condition())

    go_caller() = begin go1_condition[] = true 
                        lock(go1_[]) do 
                            notify(go1_[]#=; all=true=#) 
                        end 
                  end
    go_callee() = begin lock(go1_[]) do 
                            while !go1_condition[]
                                wait(go1_[])
                            end 
                            go1_condition[] = false 
                        end
                  end

    finish_go() = begin go2_condition[] = true 
                        lock(go2_[]) do 
                            notify(go2_[]) 
                        end 
                  end

    wait_go() = begin lock(go2_[]) do 
                        while !go2_condition[]
                            wait(go2_[]) 
                        end 
                        go2_condition[] = false 
                      end
                end
    
    @unit master begin
    
        @info "GEMM_2 master -- unit_idx=$unit_idx"
        @info "GEMM_2 master -- global_topology=$global_topology"
        @info "GEMM_2 master -- global_topology=$local_topology"

        function multiply(alfa0, beta0, a0, b0, c0)
            alpha[] = alfa0; beta[] = beta0
            a[] = a0; b[] = b0; c[] = c0

            @info "go_caller $unit_idx: notify"
            go_caller()
            @info "wait_go $unit_idx: arrive"
            wait_go()
            @info "wait_go $unit_idx: passed"
        end

        N = 1000
        aa = ones(N,N)
        bb = ones(N,N)
        cc = zeros(N,N)
        multiply(1.0, 1.0, aa, bb, cc)

    end

    @inner GEMM_2

    @unit parallel count=T worker begin
    
        @slice GEMM_2.gemm 

        @info "GEMM_2 -- unit_idx=$unit_idx"
        @info "GEMM_2 -- global_topology=$global_topology"
        @info "GEMM_2 -- global_topology=$local_topology"

        
        while true 
            @info "go_callee $unit_idx: arrive"
            go_callee()
            @info "go_callee $unit_idx: depart"
            gemm.multiply(unit_idx, alpha[], beta[], a[], b[], c[])
            @info "finish_go $unit_idx: notify"
            finish_go()
            @info "finish_go $unit_idx: passed"
        end

    end

end
