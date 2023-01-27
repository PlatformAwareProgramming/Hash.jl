using Hash

@computation multicluster GEMM_multicluster_entry begin

    using Distributed
    using ConcurrentCollections

    @unit master begin
        
        @info "master"

        function finish()
            s = topology[:source][1]
            @remotecall_fetch s GEMM_multicluster_entry.finish()
            for w in topology[:worker]
                @remotecall_fetch w GEMM_multicluster_entry.finish()
            end
        end

        function go()
            i = topology[:source][1]
            @remotecall_fetch i GEMM_multicluster_entry.main()   
        end

    end


    @unit source begin

        #M = 4000
        #N = 6000
        #P = 3000

        M = 2000
        N = 3000
        P = 1500

        MBig = Ref{Int}()
        NBig = Ref{Int}()
        PBig = Ref{Int}()

        c = Ref{Matrix}()

        mp_control = Ref{Matrix}()
        mp_control_2 = Ref{Matrix}()
        n_control = Ref{Int}()
        
        function getBlockDimensions()
            return M, N, P
        end

        function setProblem(Mbig, Nbig, Pbig)
            MBig[] = Mbig; @assert mod(MBig[], M) == 0
            NBig[] = Nbig; @assert mod(NBig[], N) == 0
            PBig[] = Pbig; @assert mod(PBig[], P) == 0
            m = div(MBig[], M)
            p = div(PBig[], P)
            n = div(NBig[], N)
            mp_control[] = zeros(m, p)
            mp_control_2[] = zeros(m, p)
            n_control[] = n
            c[] = Matrix(undef, m, p)
            return
        end

        idle_workers = DualLinkedConcurrentRingQueue{Int}()
        for w in topology[:worker] push!(idle_workers, w) end 
            
        function handle_request(id, mm_request, x, y, last_block)
            i = div(x-1, M) + 1
            j = div(y-1, P) + 1
            if !isassigned(c[], i, j)
                c[][i,j] = zeros(M, P)
            end
            c[][i,j] += fetch(mm_request)
            mp_control_2[][i, j] += 1
            if mp_control_2[][i,j] == n_control[]
                push!(block_queue_out, (last_block, x, y, c[][i,j]))
                c[][i,j] = nothing
            end

            @async push!(idle_workers, id)
        end
        
        block_queue_in  = DualLinkedConcurrentRingQueue{Any}()
        block_queue_out = DualLinkedConcurrentRingQueue{Any}()

        function finish()
            push!(block_queue_in, nothing)
            return nothing
        end
        
        # Send two blocks of matrices A e B to be multiplied in a cluster. 
        # We assume that blocks are large enough to fit the master's memory.
        function feed_block(i, j, a, b)
            @assert MBig[] > 0
            @assert NBig[] > 0 
            @assert PBig[] > 0
            @assert mod(i-1, M) == 0
            @assert mod(j-1, P) == 0            
            c = zeros(M, P)

            m = div(i-1, M) + 1
            p = div(j-1, P) + 1
            mp_control[][m, p] += 1
            @assert mp_control[][m, p] <= n_control[]

            # returns if all the blocks of matrices have been sent
            all_blocks_set = sum(mp_control[]) == n_control[] * size(mp_control[], 1) * size(mp_control[], 2)
            idx = popfirst!(idle_workers)
            item = (a, b, c, i, j, idx, all_blocks_set)
            push!(block_queue_in, item)
            return all_blocks_set
        end


        function main()

            M, N, P = getBlockDimensions()
        
            MBig = M*4
            NBig = N*4
            PBig = P*4
        
            c = zeros(MBig, PBig)
        
            setProblem(MBig, NBig, PBig)
        
            @sync begin
                Threads.@spawn begin 
                    count = Ref{Int}(1)
                    last_block = Ref{Bool}(false)
                    while !last_block[]
                        (lb, x, y, cc) = popfirst!(GEMM_multicluster_entry.block_queue_out)
                        c[x:(x+M-1), y:(y+P-1)] = cc
                        @info "output:", (count[], lb, x, y, sum(c))
                        last_block[] = lb
                        count[] = count[] + 1
                    end
                end
            
                for i in 1:M:MBig, j in 1:P:PBig
                    for k in 1:N:NBig
                        aa = ones(M, N)
                        bb = ones(P, N)
                        last_block = GEMM_multicluster_entry.feed_block(i, j, aa, bb)
                        @info "i=$i, j=$j, k=$k, last_block=$last_block"
                    end
                end
            end

            return nothing    
        end

        wait_unit(:worker)

        @async while true

            item = popfirst!(block_queue_in) 

            isnothing(item) && break
            
            (a_blk, b_blk, c_blk, i, j, idx, last_block) = item

            mmreq = @remotecall idx GEMM_multicluster_entry.multiply!($a_blk, $b_blk, $c_blk)
            
            @async handle_request(idx, mmreq, i, j, last_block)
        end

    end

    #@inner GEMM_multicluster

    @unit parallel worker begin
        
        #@slice GEMM_multicluster.gemm        
        @inner GEMM_mpi_entry

        function multiply!(a, b, c)
            r = #=gemm.=# GEMM_mpi_entry.multiply!(1.0, 1.0, a, b, c)
            @info (r[1,1], sum(r))
            return r
        end

        function finish()
            GEMM_mpi_entry.finish()
            return nothing
        end

        @info "MULTICLUSTER WORKER $unit_idx"

        notify_unit(:worker, unit_idx, :source)
    end 

end