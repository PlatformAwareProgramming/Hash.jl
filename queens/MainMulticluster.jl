using Hash
using MulticlusterManager

#@cluster local_cluster "heron@localhost" 6 dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/queens` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
@cluster cluster_1 "tcarneiropessoa@grvingt-13.nancy.grid5000.fr"  6 hostfile=`/home/tcarneiropessoa/hostfile.1` dir=`/home/tcarneiropessoa/heron/Hash.jl/queens` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
@cluster cluster_2 "tcarneiropessoa@graoully-11.nancy.grid5000.fr" 6 hostfile=`/home/tcarneiropessoa/hostfile.2` dir=`/home/tcarneiropessoa/heron/Hash.jl/queens` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
@cluster cluster_3 "tcarneiropessoa@grcinq-13.nancy.grid5000.fr" 6 hostfile=`/home/tcarneiropessoa/hostfile.4` dir=`/home/tcarneiropessoa/heron/Hash.jl/queens` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
@cluster cluster_4 "tcarneiropessoa@grappe-11.nancy.grid5000.fr" 6 hostfile=`/home/tcarneiropessoa/hostfile.5` dir=`/home/tcarneiropessoa/heron/Hash.jl/queens` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_3 "tcarneiropessoa@grvingt-1.nancy.grid5000.fr" 6 dir=`/home/tcarneiropessoa/heron/Hash.jl/queens` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_4 "tcarneiropessoa@grvingt-1.nancy.grid5000.fr" 6 dir=`/home/tcarneiropessoa/heron/Hash.jl/queens` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true

@launch QueensMulticluster worker:cluster_1 worker:cluster_2 worker:cluster_3 worker:cluster_4

@info "START !!!"

@time QueensMulticluster.queens(15) # 5.XXXXXXX seconds 
@time QueensMulticluster.queens(15)  
@time QueensMulticluster.queens(15)  
@time QueensMulticluster.queens(15)  
@time QueensMulticluster.queens(15)  

@time QueensMulticluster.queens(16) # 15.716749 seconds
@time QueensMulticluster.queens(16) 
@time QueensMulticluster.queens(16) 
@time QueensMulticluster.queens(16) 
@time QueensMulticluster.queens(16) 

@time QueensMulticluster.queens(17) # 91.408789 seconds
@time QueensMulticluster.queens(17) 
@time QueensMulticluster.queens(17) 
@time QueensMulticluster.queens(17) 
@time QueensMulticluster.queens(17) 



QueensMulticluster.finish()