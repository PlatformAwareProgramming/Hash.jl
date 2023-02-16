using Hash
using MPI
ENV["UCX_WARN_UNUSED_ENV_VARS"] = "n"

function stop()
end

MPI.Init()

@computation cluster GEMM_mpi_entry begin

    using MPI

    function block_cyclic_2D_scatter_master(comm, X, Y, M, N, m, n, a, tag)
        for i in 1:m:M
            row = mod(div(i, m), X)
            for j in 1:n:N
                col = mod(div(j, n), Y)
                rank = row * Y + col + 1
                MPI.Send(a[i:i+m-1, j:j+n-1], comm; dest = rank, tag = tag)
            end
        end
    end

    function block_cyclic_2D_gather_master(comm, X, Y, M, N, m, n, a, tag)
        buf = zeros(m, n)
        for i in 1:m:M
            row = mod(div(i, m), X)
            for j in 1:n:N
                col = mod(div(j, n), Y)
                rank = row * Y + col + 1
                MPI.Recv!(buf, comm; source = rank, tag = tag)
                a[i:i+m-1, j:j+n-1] = buf
            end
        end
    end

    function block_cyclic_2D_scatter_worker(comm, M, N, m, n, a, tag)
        for i in 1:m:M
            for j in 1:n:N
                MPI.Send(a[i:i+m-1, j:j+n-1], comm; dest = 0, tag = tag)
            end
        end
    end

    function block_cyclic_2D_gather_worker(comm, M, N, m, n, a, tag)
        buf = zeros(m, n)
        for i in 1:m:M
            for j in 1:n:N
                MPI.Recv!(buf, comm; source = 0, tag = tag)
                a[i:i+m-1, j:j+n-1] = buf
            end
        end
    end

    X = Ref{Int}(2)
    Y = Ref{Int}(2)

    all_comm = Ref{MPI.Comm}(MPI.COMM_NULL)

    @unit master begin    

        @info "======>>>> MASTER unit_idx = $unit_idx, topology = $topology, local_topology = $local_topology"

        using MPI

        function setGrid(newX, Ynew)
            X[] = newX
            Y[] = newY
        end

        function multiply!(alpha, beta, a, b, c)
            ma = 125 #125 # 500 250
            n  = 125 
            pb = 125
            mc = 125
            pc = 125
            multiply!(X[], Y[], ma, n, pb, mc, pc, alpha, beta, a, b, c)
        end

        root = topology[:master][1]
        comm_size = MPI.Comm_size(MPI.COMM_WORLD)

        world_group = MPI.Comm_group(MPI.COMM_WORLD)
        all_group = MPI.Group_excl(world_group, Int32[i for i in X[]*Y[]+1:comm_size-1])
        all_comm[] = MPI.Comm_create(MPI.COMM_WORLD, all_group)

        workers_group = MPI.Group_excl(all_group, Int32[root])
        MPI.Comm_create(all_comm[], workers_group)

        function multiply!(X_, Y_, ma, n, pb, mc, pc, alpha, beta, a, b, c)

            M = size(a,1)
            N = size(a,2); @assert size(b,2) == N
            P = size(b,1)

            root = topology[:master][1]
            all_comm_size = MPI.Comm_size(all_comm[])
            for i in 0:all_comm_size-1
                if i != root
                    MPI.Send(false, all_comm[]; dest = i, tag = 444)
                end
            end

            MPI.bcast((X_, Y_, M, N, P, ma, n, pb, mc, pc, alpha, beta), root,all_comm[])

            block_cyclic_2D_scatter_master(all_comm[], X_, Y_, M, N, ma, n, a, 111)            
            block_cyclic_2D_scatter_master(all_comm[], X_, Y_, P, N, pb, n, b, 222)
            block_cyclic_2D_gather_master(all_comm[], X_, Y_, M, P, mc, pc, c, 333)

            return c
        end

        function finish()
            @info "CALL FINISH $(topology[:worker])"
            all_comm_size = MPI.Comm_size(all_comm[])
            for i in 0:all_comm_size-1
                if i != root
                    MPI.Send(true, all_comm[]; dest = i, tag = 444)
                end
            end
        end

    end

    @inner GEMM_mpi

    @unit parallel count=N worker begin

        using MPI

        workers_comm = Ref{MPI.Comm}(MPI.COMM_NULL)

        @slice GEMM_mpi.gemm

        root = topology[:master][1]

        comm_size = MPI.Comm_size(MPI.COMM_WORLD)

        world_group = MPI.Comm_group(MPI.COMM_WORLD)
        all_group = MPI.Group_excl(world_group, Int32[i for i in X[]*Y[]+1:comm_size-1])
        all_comm[] = MPI.Comm_create(MPI.COMM_WORLD, all_group)

        if all_comm[] != MPI.COMM_NULL 
            workers_group = MPI.Group_excl(all_group, Int32[root])
            workers_comm[] = MPI.Comm_create(all_comm[], workers_group)

            termination_flag = Ref{Bool}(MPI.Recv(Bool, all_comm[]; source=root, tag = 444))
            
            while (!termination_flag[])

                (X_, Y_, M, N, P, ma, n, pb, mc, pc, alpha, beta) = MPI.bcast(nothing, all_comm[])

                Mx = div(M, X_)
                Ny = div(N, Y_)
                Px = div(P, X_)
                Py = div(P, Y_)
                
                a = zeros(Mx, Ny)
                b = zeros(Px, Ny)
                c = zeros(Mx, Py)

                block_cyclic_2D_gather_worker(all_comm[], Mx, Ny, ma, n, a, 111)
                block_cyclic_2D_gather_worker(all_comm[], Px, Ny, pb, n, b, 222)

                gemm.multiply!(workers_comm[], X_, Y_, pb, pc, alpha, beta, a, b, c)

                block_cyclic_2D_scatter_worker(all_comm[], Mx, Py, mc, pc, c, 333)

                termination_flag[] = MPI.Recv(Bool, all_comm[]; source=root, tag = 444)
            end
        end
    end

end
