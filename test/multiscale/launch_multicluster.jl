
@cluster aws_cluster "ubuntu@35.168.113.144" 4 sshflags=`-i /home/heron/hpc-shelf-credential.pem` dir=`/home/ubuntu/work` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true
@cluster local_cluster "heron@localhost" 4 dir=`/home/heron/Dropbox/Copy/ufc_mdcc_hpc/Hash.jl/test/multiscale` exename=`/opt/julia-1.8.3/bin/julia` tunnel=true

@launch TestMulticluster worker:local_cluster