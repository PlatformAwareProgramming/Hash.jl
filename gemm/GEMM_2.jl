
@computation manycore GEMM_2 begin
    
    @unit parallel gemm begin

        include("mm.jl")

        function multiply(idx, alpha, beta, a, b, c)

            size = size(a,1)
            @assert size == size(a,2) == size(b,1) == size(b,2) == size(c,1) == size(c,2)

            N  = unit_size
            id = unit_idx

            bs = block_size[3]    # block size.
            nb = Int64(size/bs)   # number of blocks.
        
            count = 1
            for i in 0:nb-1, j in 0:nb-1, k in 0:nb-1
                if mod(count, N) == id
                    mm(Val(2), bs, a, b, c, 1 + i*bs, 1 + k*bs, 1 + k*bs, 1 + j*bs)
                end
                count += 1                
            end
    
        end

    end

end