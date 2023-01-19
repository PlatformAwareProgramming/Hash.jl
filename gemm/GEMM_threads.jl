
@computation manycore GEMM_threads begin
    
    @unit parallel gemm begin

        include("mm.jl")
        
        N = length(topology[:gemm])

        function multiply!(id, alpha, beta, a, b, c)

            # c .= a * b

            bs = block_size[3] # block size.
            m = size(a,1)
            n = size(a,2)
            p = size(b,1)
            nbm = Int64(m/bs)   # number of blocks.
            nbn = Int64(n/bs)   # number of blocks.
            nbp = Int64(p/bs)   # number of blocks.
        
            count = 0
            for i in 0:nbm-1, j in 0:nbp-1, k in 0:nbn-1
                if mod(count, N) == id-1
                    mm(Val(3), bs, a, b, c, 1 + i*bs, 1 + k*bs, 1 + k*bs, 1 + j*bs)
                end
                count += 1                
            end

        end

    end

end