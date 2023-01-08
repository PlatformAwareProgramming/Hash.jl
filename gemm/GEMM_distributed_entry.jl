
using MPIClusterManagers, Distributed, MPI

manager = MPIClusterManagers.start_main_loop(MPI_TRANSPORT_ALL)
function stop()
    MPIClusterManagers.stop_main_loop(manager)
end

@everywhere using Hash

@everywhere @computation remotecall GEMM_distributed_entry begin

    using Distributed
    using MPI
    MPI.Init()

    @unit master begin

        using Distributed 

        @info "======>>>> master unit_idx = $unit_idx, topology = $topology, local_topology = $local_topology"

        world_comm = MPI.COMM_WORLD
        world_group = MPI.Comm_group(world_comm)
        workers_group = MPI.Group_excl(world_group, Int32[0])
        MPI.Comm_create(world_comm, workers_group)

        @info "............................................................ rank = $(MPI.Comm_rank(world_comm))"


        function reorder_matrix!(X, Y, M, N, m, n, a)
            aux = zeros(m,n)
            for i in 1:m:M
                ti = div(i, m)
                row = mod(ti, X)
                for k in 0:Y-1
                  for j in k*n*Y+(k+1)*n+1:n:(k+1)*n*Y
                    tj = div(j, n)
                    col = mod(tj, Y)
                    p = row * div(M,X) + div(ti,X) * m + 1
                    q = col * div(N,Y) + div(tj,Y) * n + 1
                    aux = a[i:i+m-1, j:j+n-1]
                    a[i:i+m-1, j:j+n-1] = a[p:p+m-1, q:q+n-1]
                    a[p:p+m-1, q:q+n-1] = aux
                  end  
                end
            end
        end
        
        function multiply!(X, Y, M, N, P, ma, n, pb, mc, pc, alpha, beta, a, b, c)

            @info "MULTIPLY ............................................................"

            reorder_matrix!(X, Y, M, N, ma, n, a)
            reorder_matrix!(X, Y, P, N, pb, n, b)

            @sync begin
                for row in 0:X-1
                    for col in 0:Y-1
                        widx = row * Y + col + 1
                        wpid = topology[:worker][widx]                    
                        Mx = div(M, X)
                        Ny = div(N, Y)
                        Px = div(P, X)
                        Py = div(P, Y)
                        rMx = row * Mx + 1
                        rNy = col * Ny + 1
                        rPx = row * Px + 1
                        rPy = col * Py + 1

                        @info "REMOTE CALL $wpid begin"
                        #buf = Distributed.@spawnat wpid multiply!(X, Y, Mx, Py, pb, pc, alpha, beta, a[rMx:rMx+Mx-1,rNy:rNy+Ny-1], b[rPx:rPx+Px-1,rNy:rNy+Ny-1])
                        buf = remotecall(multiply!, wpid, X, Y, Mx, Py, pb, pc, alpha, beta, a[rMx:rMx+Mx-1,rNy:rNy+Ny-1], b[rPx:rPx+Px-1,rNy:rNy+Ny-1])
                        #buf = remotecall(multiply2, 2)
                        #@info "REMOTE CALL $wpid end"

                        #@info fetch(buf)
                        @async c[rMx:rMx+Mx-1,rPy:rPy+Py-1] = fetch(buf)

                    end
                end
            end
        end

    end

    @inner GEMM_distributed


    @unit parallel count=W worker begin

        @info "======>>>> worker unit_idx = $unit_idx, topology = $topology, local_topology = $local_topology"

        world_comm = MPI.COMM_WORLD
        world_group = MPI.Comm_group(world_comm)
        workers_group = MPI.Group_excl(world_group, Int32[0])
        workers_comm = MPI.Comm_create(world_comm, workers_group)

        @info "............................................................ rank = $(MPI.Comm_rank(world_comm))"

        @slice GEMM_distributed.gemm
        #@inner GEMM_threads_entry


        function multiply!(X, Y, Mx, Py, pb, pc, alpha, beta, a, b)
             
            @info "=>=>=>=>=>=> start $unit_idx"
        
            c = zeros(Mx, Py)

            @info "AAAAAAAAAx = $(size(a,1)), AAAAAAAAy = $(size(a,2))"
            @info "BBBBBBBBBx = $(size(b,1)), BBBBBBBBy = $(size(b,2))"

            #=GEMM_threads_entry=#gemm.multiply!(workers_comm, X, Y, pb, pc, alpha, beta, a, b, c)
    
            @info "=>=>=>=>=>=> finish $unit_idx"

            return c
        end

    end

end
