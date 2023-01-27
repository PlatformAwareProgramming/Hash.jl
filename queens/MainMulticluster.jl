using Hash
using MulticlusterManager

#@cluster local_cluster "heron@localhost" 6 dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/queens` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
@cluster cluster_1 "tcarneiropessoa@grvingt-12.nancy.grid5000.fr"  6 hostfile=`/home/tcarneiropessoa/hostfile.1` dir=`/home/tcarneiropessoa/heron/Hash.jl/queens` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
@cluster cluster_2 "tcarneiropessoa@graoully-1.nancy.grid5000.fr" 6 hostfile=`/home/tcarneiropessoa/hostfile.2` dir=`/home/tcarneiropessoa/heron/Hash.jl/queens` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
@cluster cluster_3 "tcarneiropessoa@grappe-1.nancy.grid5000.fr" 1 hostfile=`/home/tcarneiropessoa/hostfile.3` dir=`/home/tcarneiropessoa/heron/Hash.jl/queens` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_3 "tcarneiropessoa@grvingt-1.nancy.grid5000.fr" 6 dir=`/home/tcarneiropessoa/heron/Hash.jl/queens` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_4 "tcarneiropessoa@grvingt-1.nancy.grid5000.fr" 6 dir=`/home/tcarneiropessoa/heron/Hash.jl/queens` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true

@launch QueensMulticluster worker:cluster_1 # worker:local_cluster worker:local_cluster worker:local_cluster

@time QueensMulticluster.queens(20)

QueensMulticluster.finish()