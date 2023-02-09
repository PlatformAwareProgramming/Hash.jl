using Hash

@computation multicluster GEMM_multicluster_entry begin

    using Distributed
    using ConcurrentCollections

 
    @unit master begin

        # the master sends the C block index to the source units.    

        indexes_A = Dict{Int, Vector{Tuple{Int,Int}}}()        
        indexes_B = Dict{Int, Vector{Tuple{Int,Int}}}()        
        indexes_C = Dict{Int, Vector{Tuple{Int,Int}}}()        

        function finish()
            for s in topology[:source]
                @remotecall_fetch s GEMM_multicluster_entry.finish()
            end
            for w in topology[:worker]
                @remotecall_fetch w GEMM_multicluster_entry.finish()
            end
        end

        function totalNeighborhood()
            n = Dict()
            for r in 1:length(topology[:source]), s in 1:length(topology[:source])
                !haskey(n, r) && (n[r] = [])
                r != s && push!(n[r], s)
            end
            return n
        end

        function go()

            Threads.@threads for sidx in topology[:source]
                @remotecall_fetch sidx GEMM_multicluster_entry.perform()   
            end
        end

        DIM = Ref{Tuple{Int,Int,Int}}()

        function distribute_indexes(r, s, indexes)
            source_size = length(topology[:source])
            
            sidx = Ref{Int}(1)
            for i in 1:DIM[][r], j in 1:DIM[][s]
                !haskey(indexes, sidx[]) && (indexes[sidx[]] = [])
                push!(indexes[sidx[]], (i,j))
                sidx[] = mod(sidx[], source_size) + 1
            end
        end

        function setProblem(nM, nN, nP)
            DIM[] = (nM, nN, nP)
            distribute_indexes(1, 2, indexes_A)
            distribute_indexes(3, 2, indexes_B)
            distribute_indexes(1, 3, indexes_C)

            @info "INDEXES A: $indexes_A"
            @info "INDEXES B: $indexes_B"
            @info "INDEXES C: $indexes_C"

            Threads.@threads for i in 1:length(topology[:source])
                sidx = topology[:source][i]
                @remotecall_fetch sidx GEMM_multicluster_entry.setIndexesAB($indexes_A[$i], $indexes_B[$i], $i)
                @remotecall_fetch sidx GEMM_multicluster_entry.setIndexesC($indexes_C[$i], $i)
            end

            n = totalNeighborhood()            
            Threads.@threads for i in 1:length(topology[:source])
                sidx = topology[:source][i]
                @remotecall_fetch sidx GEMM_multicluster_entry.exchangeMappingInfo($n[$i])
            end
        end

    end

    # source and worker are supposedly in the same network domain (one-by-one correspondence)

    @unit parallel source begin

        # the source units have a local index for matrices A and B
        indexes_A = Dict{Tuple{Int,Int}, Int}()        
        indexes_B = Dict{Tuple{Int,Int}, Int}()        
        indexes_C = Dict{Tuple{Int,Int}, Int}()        
    
        # cluster-level block sizes
        M = 1000
        N = 1500
        P = 750

        a = Dict{Tuple{Int,Int}, Matrix}() 
        b = Dict{Tuple{Int,Int}, Matrix}() 
        c = Dict{Tuple{Int,Int}, Matrix}() 
        
        #neighborhood = Vector{Int}()

        last_j = Ref{Int}(0)

        # first called by the master and then by the connected sources
        function setIndexesAB(ixA, ixB, idx)
            @info "$unit_idx setting indexes(AB) from $idx: $ixA / $ixB"
            for (i,k) in ixA
                @assert !haskey(indexes_A, (i,k))
                indexes_A[(i,k)] = idx
                if idx == unit_idx
                    a[(i,k)] = ones(M,N)
                end
            end
            for (j,k) in ixB
                @assert !haskey(indexes_B, (j,k))
                j > last_j[] && (last_j[] = j)
                indexes_B[(j,k)] = idx
                if idx == unit_idx
                    b[(j,k)] = ones(P,N)
                end
            end
        end

        # called by the master and then by the connected sources
        function setIndexesC(ixC, idx)
            @info "$unit_idx setting indexes(C) from $idx: $ixC"
            for (i,j) in ixC
                @assert !haskey(indexes_C, (i,j))
                indexes_C[(i,j)] = idx
                if idx == unit_idx
                    c[(i,j)] = zeros(M,P)
                end
            end
        end

        getIndexesAB() = keys(a), keys(b)
        getIndexesC() = keys(c)

        #function setNeighborhood(nei)
        #    @info "$unit_idx receiving neighborhood from master: $nei"
        #    for i in nei
        #        @assert i in 1:length(topology[:source])
        #        push!(neighborhood, i) 
        #    end
        #end

        function exchangeMappingInfo(neighborhood)
            @info "$unit_idx: exchangeMappingInfo --- $neighborhood"
            for i in neighborhood
                sidx = topology[:source][i]
                @info "begin $unit_idx call getIndexesAB in $i"
                idxA, idxB = @remotecall_fetch sidx GEMM_multicluster_entry.getIndexesAB()
                setIndexesAB(idxA, idxB, i)
                @info "end $unit_idx call getIndexesAB in $i"
            end
            for sidx in topology[:source]
                if sidx != topology[:source][unit_idx]
                    i = indexin(sidx, topology[:source])[]
                    @info "begin $unit_idx call getIndexesC in $i"
                    idxC = @remotecall_fetch sidx GEMM_multicluster_entry.getIndexesC()
                    setIndexesC(idxC, i)
                    @info "end $unit_idx call getIndexesC in $i"
                end
            end
        end


        #function check_indexes()
        #end

        block_queue_in  = DualLinkedConcurrentRingQueue{Any}()

        function feed_block(i, j, k, a, sunit_idx_b)
            c = zeros(M, P)
            idx_w = topology[:worker][unit_idx]
            item = (i, j, k, a, c, idx_w, sunit_idx_b)
            push!(block_queue_in, item)
        end

        function perform()

            #exchangeMappingInfo()
            #check_indexes() 

            @async while true

                item = popfirst!(block_queue_in) 
    
                isnothing(item) && break
                
                (i, j, k, a_blk, c_blk, idx_w, sunit_idx_b) = item
                @info "TAKE unit_idx = $unit_idx: i=$i, j=$j, k=$k, idx_w=$idx_w, sunit_idx_b=$sunit_idx_b"
    
                b_blk = if sunit_idx_b == unit_idx 
                             b[(j,k)] 
                        else 
                            sidx = topology[:source][sunit_idx_b]
                            @remotecall_fetch sidx GEMM_multicluster_entry.get_b_block($j,$k)
                        end
                
                mmreq = @remotecall idx_w GEMM_multicluster_entry.multiply!($a_blk, $b_blk, $c_blk)
                
                @async handle_request(mmreq, i, j)
            end

            for (i,k) in keys(a)
                for j in 1:(last_j[])
                    sunit_idx_b = indexes_B[(j,k)]
                    GEMM_multicluster_entry.feed_block(i, j, k, a[i,k], sunit_idx_b)    
                    @info "$unit_idx: **** FEED BLOCK i=$i j=$j k=$k sunit_idx_b=$sunit_idx_b last_j=$(last_j[])"
                end
            end
        end

        function set_c_block(cc, i, j)
            @assert indexes_C[(i,j)] == unit_idx 
            if !haskey(c,(i,j))
                c[(i,j)] = zeros(M, P)
            end
            c[(i,j)] += cc
            @info "c[($i,$j)][1,1] UPDATE $(c[(i,j)][1,1]))"
            return
        end

        function get_b_block(j, k)
            @assert indexes_B[(j,k)] == unit_idx 
            return b[(j,k)]
        end

        function handle_request(mm_request, i, j)
            cc = fetch(mm_request)
            sunit_idx_c = indexes_C[(i,j)]
            cidx = topology[:source][sunit_idx_c]
            # send c block to the correct source ... 
            @remotecall_fetch cidx GEMM_multicluster_entry.set_c_block($cc, $i, $j)
        end

        function finish()
            @info "finish source"
            push!(block_queue_in, nothing)
            return nothing
        end

       #wait_unit(:worker)

    end

    @unit parallel worker begin
        
        @inner GEMM_mpi_entry

        multiply!(a, b, c) = GEMM_mpi_entry.multiply!(1.0, 1.0, a, b, c)

        finish() = GEMM_mpi_entry.finish()

        @info "MULTICLUSTER WORKER $unit_idx"

       # notify_unit(:worker, unit_idx, :source)
    
    end 

end