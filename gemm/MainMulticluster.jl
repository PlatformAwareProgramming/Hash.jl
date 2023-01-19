using Hash
using MulticlusterManager

@cluster local_cluster "heron@localhost" 6 dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true

@launch GEMM_multicluster_entry worker:local_cluster worker:local_cluster #worker:local_cluster

M, N, P = GEMM_multicluster_entry.getBlockDimensions()

MBig = M*4
NBig = N*4
PBig = P*4

c = zeros(MBig, PBig)

GEMM_multicluster_entry.setProblem(MBig, NBig, PBig)

for i in 1:M:MBig, j in 1:P:PBig
    for k in 1:N:NBig
        aa = ones(M, N)
        bb = ones(P, N)
        cc = zeros(M, P)
        last_block = GEMM_multicluster_entry.feed_block(i, j, aa, bb)
        @info "i=$i, j=$j, k=$k, last_block=$last_block"
    end
end

