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
#@cluster cluster_11 "tcarneiropessoa@grvingt-10.nancy.grid5000.fr" 1 which_mpi="OpenMPI" hostfile=`/home/tcarneiropessoa/hostfile.1` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_12 "tcarneiropessoa@grvingt-10.nancy.grid5000.fr" 4 which_mpi="OpenMPI" hostfile=`/home/tcarneiropessoa/hostfile.1` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_g1 "tcarneiropessoa@54.147.135.128" 1 which_mpi="OpenMPI" hostfile=`/home/tcarneiropessoa/hostfile.1` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` sshflags=`-i /home/tcarneiropessoa/heron/.ssh-carneiro/id_rsa -p 8080` scpflags=`-i /home/tcarneiropessoa/heron/.ssh-carneiro/id_rsa -P 8080` tunnel=true
#@cluster cluster_g2 "tcarneiropessoa@54.147.135.128" 4 which_mpi="OpenMPI" hostfile=`/home/tcarneiropessoa/hostfile.1` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` sshflags=`-i /home/tcarneiropessoa/heron/.ssh-carneiro/id_rsa -p 8080` scpflags=`-i /home/tcarneiropessoa/heron/.ssh-carneiro/id_rsa -P 8080` tunnel=true
@cluster cluster_g1 "tcarneiropessoa@54.147.135.128:8080" nothing 1 which_mpi="OpenMPI" hostfile=`/home/tcarneiropessoa/hostfile.1` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` sshflags=`-i /home/heron/hpc-shelf-credential.pem` scpflags=`-i /home/heron/hpc-shelf-credential.pem -P 8080` tunnel=true
@cluster cluster_g2 "tcarneiropessoa@54.147.135.128:8080" nothing 4 which_mpi="OpenMPI" hostfile=`/home/tcarneiropessoa/hostfile.1` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` sshflags=`-i /home/heron/hpc-shelf-credential.pem` scpflags=`-i /home/heron/hpc-shelf-credential.pem -P 8080` tunnel=true
#@cluster cluster_2 "tcarneiropessoa@graoully-12.nancy.grid5000.fr" 6 hostfile=`/home/tcarneiropessoa/hostfile.2` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_4 "tcarneiropessoa@grcinq-13.nancy.grid5000.fr" 6 hostfile=`/home/tcarneiropessoa/hostfile.4` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_5 "tcarneiropessoa@grappe-11.nancy.grid5000.fr" 6 hostfile=`/home/tcarneiropessoa/hostfile.5` dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_3 "tcarneiropessoa@grvingt-1.nancy.grid5000.fr" 6 dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true
#@cluster cluster_4 "tcarneiropessoa@grvingt-1.nancy.grid5000.fr" 6 dir=`/home/tcarneiropessoa/heron/Hash.jl/gemm` exename=`/home/tcarneiropessoa/julia-1.8.2/bin/julia` tunnel=true

@cluster cluster_s11 "heron@localhost" nothing 1 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
@cluster cluster_s12 "heron@localhost" nothing 4 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
#@cluster cluster_w1 "heron@localhost" 6 hostfile=`/home/heron/hostfile` dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/gemm` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true

#@cluster cluster_lux1 "tcarneiro@54.147.135.128" 1 which_mpi="OpenMPI" hostfile=`/home/users/tcarneiro/heron/hostfile` dir=`/home/users/tcarneiro/heron/Hash.jl/gemm` exename=`/home/users/tcarneiro/heron/julia-1.8.5/bin/julia` sshflags=`-i /home/tcarneiropessoa/heron/hpc-shelf-credential.pem -p 8081` scpflags=`-i /home/tcarneiropessoa/heron/hpc-shelf-credential.pem -P 8081` tunnel=true
#@cluster cluster_lux2 "tcarneiro@54.147.135.128" 4 which_mpi="OpenMPI" hostfile=`/home/users/tcarneiro/heron/hostfile` dir=`/home/users/tcarneiro/heron/Hash.jl/gemm` exename=`/home/users/tcarneiro/heron/julia-1.8.5/bin/julia` sshflags=`-i /home/tcarneiropessoa/heron/hpc-shelf-credential.pem -p 8081` scpflags=`-i /home/tcarneiropessoa/heron/hpc-shelf-credential.pem -P 8081` tunnel=true
@cluster cluster_lux1 "tcarneiro@54.147.135.128:8081" nothing 1 which_mpi="OpenMPI" hostfile=`/home/users/tcarneiro/heron/hostfile` dir=`/home/users/tcarneiro/heron/Hash.jl/gemm` exename=`/home/users/tcarneiro/heron/julia-1.8.5/bin/julia` sshflags=`-i /home/heron/hpc-shelf-credential.pem` scpflags=`-i /home/heron/hpc-shelf-credential.pem -P 8081` tunnel=true
@cluster cluster_lux2 "tcarneiro@54.147.135.128:8081" nothing 4 which_mpi="OpenMPI" hostfile=`/home/users/tcarneiro/heron/hostfile` dir=`/home/users/tcarneiro/heron/Hash.jl/gemm` exename=`/home/users/tcarneiro/heron/julia-1.8.5/bin/julia` sshflags=`-i /home/heron/hpc-shelf-credential.pem` scpflags=`-i /home/heron/hpc-shelf-credential.pem -P 8081` tunnel=true
#@cluster cluster_lux "tcarneiro@localhost" 4 which_mpi="OpenMPI" hostfile=`/home/users/tcarneiro/heron/hostfile` dir=`/home/users/tcarneiro/heron/Hash.jl/gemm` exename=`/home/users/tcarneiro/heron/julia-1.8.5/bin/julia` sshflags=`-i /home/heron/hpc-shelf-credential.pem -p 8079` scpflags=`-i /home/heron/hpc-shelf-credential.pem -P 8079` tunnel=true

#@launch GEMM_multicluster_entry source:cluster_s1 source:cluster_s2 source:cluster_s3 source:cluster_s4 worker:cluster_w1 worker:cluster_w2 worker:cluster_w3 worker:cluster_w4
@launch GEMM_multicluster_entry source:cluster_g1 source:cluster_lux1 worker:cluster_g2 worker:cluster_lux2

GEMM_multicluster_entry.setProblem(4, 4, 4)

@time GEMM_multicluster_entry.go()
#@time GEMM_multicluster_entry.go()
#@time GEMM_multicluster_entry.go()
#@time GEMM_multicluster_entry.go()
#@time GEMM_multicluster_entry.go()


