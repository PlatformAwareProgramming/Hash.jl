using Hash
using MulticlusterManager

#@cluster cluster_s1 "heron@localhost" 1 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
#@cluster cluster_s2 "heron@localhost" 1 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
#@cluster cluster_s3 "heron@localhost" 1 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
#@cluster cluster_s4 "heron@localhost" 1 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
#@cluster cluster_w1 "heron@localhost" 6 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
#@cluster cluster_w2 "heron@localhost" 6 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
#@cluster cluster_w3 "heron@localhost" 6 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
#@cluster cluster_w4 "heron@localhost" 6 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true

#@cluster cluster_3 "tcarneiropessoa@grappe-3.nancy.grid5000.fr" 1 hostfile=`/home/tcarneiropessoa/hostfile.3` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
@cluster cluster_1 "tcarneiropessoa@grvingt-18.nancy.grid5000.fr"  6 hostfile=`/home/tcarneiropessoa/hostfile.1` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_2 "tcarneiropessoa@graoully-12.nancy.grid5000.fr" 6 hostfile=`/home/tcarneiropessoa/hostfile.2` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_4 "tcarneiropessoa@grcinq-13.nancy.grid5000.fr" 6 hostfile=`/home/tcarneiropessoa/hostfile.4` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_5 "tcarneiropessoa@grappe-11.nancy.grid5000.fr" 6 hostfile=`/home/tcarneiropessoa/hostfile.5` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_3 "tcarneiropessoa@grvingt-1.nancy.grid5000.fr" 6 dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_4 "tcarneiropessoa@grvingt-1.nancy.grid5000.fr" 6 dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true

#@cluster cluster_s1 "heron@localhost" 1 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
#@cluster cluster_w1 "heron@localhost" 6 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true


#@launch GEMM_multicluster_entry source:cluster_s1 source:cluster_s2 source:cluster_s3 source:cluster_s4 worker:cluster_w1 worker:cluster_w2 worker:cluster_w3 worker:cluster_w4
@launch GEMM_multicluster_entry source:cluster_1 worker:cluster_1

GEMM_multicluster_entry.setProblem(4, 4, 4)

@time GEMM_multicluster_entry.go()
#@time GEMM_multicluster_entry.go()
#@time GEMM_multicluster_entry.go()
#@time GEMM_multicluster_entry.go()
#@time GEMM_multicluster_entry.go()

GEMM_multicluster_entry.finish()

