using Hash
using MulticlusterManager

#@cluster local_cluster "heron@localhost" 6 dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
@cluster cluster_3 "tcarneiropessoa@grappe-1.nancy.grid5000.fr" 1 hostfile=`/home/tcarneiropessoa/hostfile.3` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
@cluster cluster_1 "tcarneiropessoa@grvingt-10.nancy.grid5000.fr"  6 hostfile=`/home/tcarneiropessoa/hostfile.1` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
@cluster cluster_2 "tcarneiropessoa@graoully-12.nancy.grid5000.fr" 6 hostfile=`/home/tcarneiropessoa/hostfile.2` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
@cluster cluster_2 "tcarneiropessoa@grcinq-13.nancy.grid5000.fr" 6 hostfile=`/home/tcarneiropessoa/hostfile.4` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_3 "tcarneiropessoa@grvingt-1.nancy.grid5000.fr" 6 dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_4 "tcarneiropessoa@grvingt-1.nancy.grid5000.fr" 6 dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true

@launch GEMM_multicluster_entry source:cluster_3 worker:cluster_1 worker:cluster_2 # worker:local_cluster

@time GEMM_multicluster_entry.go()

GEMM_multicluster_entry.finish()

