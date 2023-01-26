using Hash
using MulticlusterManager

#@cluster local_cluster "heron@localhost" 6 dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
@cluster local_cluster "tcarneiropessoa@grvingt-1.nancy.grid5000.fr" 6 dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true

@launch GEMM_multicluster_entry worker:local_cluster #worker:local_cluster worker:local_cluster

function main()

    M, N, P = GEMM_multicluster_entry.getBlockDimensions()

    MBig = M*4
    NBig = N*4
    PBig = P*4

    c = zeros(MBig, PBig)

    GEMM_multicluster_entry.setProblem(MBig, NBig, PBig)

    Threads.@spawn begin 
        count = Ref{Int}(1)
        last_block = Ref{Bool}(false)
        while !last_block[]
            (lb, x, y, cc) = popfirst!(GEMM_multicluster_entry.block_queue_out)
            c[x:(x+M-1), y:(y+P-1)] = cc
            @info (count[], lb, x, y, sum(c))
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

    GEMM_multicluster_entry.finish()

end

@time main()