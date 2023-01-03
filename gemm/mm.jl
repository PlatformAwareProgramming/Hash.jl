using BenchmarkTools

block_size = [25, 50, 200]

function mm(::Val{0}, size, a, b, c, a_x, a_y, b_x, b_y)

    limit_i   = a_x + size; 
    limit_j   = b_y + size;
    limit_k_a = a_y + size;

    for i in a_x:limit_i-1
        for j in b_y:limit_j-1
            k_b = b_x
            for k_a in a_y:limit_k_a-1
                c[i,j] += a[i,k_a] * b[k_b,j]
                k_b += 1
            end
        end
     end

end

function mm(::Val{level}, size, a, b, c, a_x, a_y, b_x, b_y) where {level}

    bs = block_size[level]  # block size.
    nb = Int64(size/bs)     # number of blocks.

    for i in 0:nb-1, j in 0:nb-1, k in 0:nb-1
        mm(Val(level-1), bs, a, b, c, a_x + i*bs, a_y + k*bs, b_x + k*bs, b_y + j*bs)
    end

end


function mm(::Val{3}, size, a, b, c, a_x, a_y, b_x, b_y)

    bs = block_size[3]    # block size.
    nb = Int64(size/bs)   # number of blocks.

    indexes = []
    for i in 0:nb-1, j in 0:nb-1, k in 0:nb-1
        push!(indexes, (i,j,k))
    end

    Threads.@threads for (i,j,k) in indexes
        mm(Val(2), bs, a, b, c, a_x + i*bs, a_y + k*bs, b_x + k*bs, b_y + j*bs)
    end

end


function mm(size, a, b, c)
    for i in 1:size, j in 1:size, k in 1:size
        c[i,j] += a[i,k] * b[k,j]
    end
end

function main()

    N = parse(Int64, ARGS[1])
    P = parse(Int64, ARGS[2])

   @info "start ... N=$N P=$P"
 
   a = ones(N,N)
   b = ones(N,N)
   c = zeros(N,N)
   @btime mm($N, $a, $b, $c)
 
   a = ones(N,N)
   b = ones(N,N)
   c = zeros(N,N)
   @btime mm(Val(3), $N, $a, $b, $c, 1, 1, 1, 1)

   @time c2 = a*b

   #@info c[Int64(N/2),Int64(N/2)]
   @info c[1,1]
   @info c[N,N]
   @info c[1,N]
   @info c[N,1]

   #@info c2[Int64(N/2),Int64(N/2)]
   @info c2[1,1]

end
