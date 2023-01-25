using Hash
using MulticlusterManager

@cluster local_cluster "heron@localhost" 4 dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/queens` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true

@launch QueensMulticluster worker:local_cluster # worker:local_cluster worker:local_cluster worker:local_cluster
