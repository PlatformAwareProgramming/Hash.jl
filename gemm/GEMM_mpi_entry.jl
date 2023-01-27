using Hash
using MPI

function stop()
end

MPI.Init()

@computation cluster GEMM_mpi_entry begin

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

    
    @unit master begin    

        @info "======>>>> MASTER unit_idx = $unit_idx, topology = $topology, local_topology = $local_topology"

        using MPI

        function multiply!(alpha, beta, a, b, c)
            X = 2
            Y = 3
            ma = 500
            n  = 500
            pb = 500
            mc = 500
            pc = 500
            multiply!(X, Y, ma, n, pb, mc, pc, alpha, beta, a, b, c)
        end

        world_comm = MPI.COMM_WORLD
        world_group = MPI.Comm_group(world_comm)
        workers_group = MPI.Group_excl(world_group, Int32[0])
        MPI.Comm_create(world_comm, workers_group)

        function multiply!(X, Y, ma, n, pb, mc, pc, alpha, beta, a, b, c)

            M = size(a,1)
            N = size(a,2); @assert size(b,2) == N
            P = size(b,1)

            for i in topology[:worker]
                MPI.Send(false, world_comm; dest = i, tag = 444)
            end

            root = topology[:master][1]
            MPI.bcast((X, Y, M, N, P, ma, n, pb, mc, pc, alpha, beta), root, world_comm)

            block_cyclic_2D_scatter_master(world_comm, X, Y, M, N, ma, n, a, 111)            
            block_cyclic_2D_scatter_master(world_comm, X, Y, P, N, pb, n, b, 222)
            block_cyclic_2D_gather_master(world_comm, X, Y, M, P, mc, pc, c, 333)

            return c
        end



        function multiply_perform()
        end


        function finish()
            @info "CALL FINISH $(topology[:worker])"
            for i in topology[:worker]
                MPI.Send(true, world_comm; dest = i, tag = 444)
            end
        end

    end

    @inner GEMM_mpi

    @unit parallel count=N worker begin

        using MPI

        @slice GEMM_mpi.gemm

        root = topology[:master][1]

        world_comm = MPI.COMM_WORLD
        world_group = MPI.Comm_group(world_comm)
        workers_group = MPI.Group_excl(world_group, Int32[root])
        workers_comm = MPI.Comm_create(world_comm, workers_group)

        termination_flag = Ref{Bool}(false)

        termination_flag[] = MPI.Recv(Bool, world_comm; source=root, tag = 444)
        while (!termination_flag[])

            (X, Y, M, N, P, ma, n, pb, mc, pc, alpha, beta) = MPI.bcast(nothing, world_comm)

            Mx = div(M, X)
            Ny = div(N, Y)
            Px = div(P, X)
            Py = div(P, Y)
            
            a = zeros(Mx, Ny)
            b = zeros(Px, Ny)
            c = zeros(Mx, Py)

            block_cyclic_2D_gather_worker(world_comm, Mx, Ny, ma, n, a, 111)
            block_cyclic_2D_gather_worker(world_comm, Px, Ny, pb, n, b, 222)

            gemm.multiply!(workers_comm, X, Y, pb, pc, alpha, beta, a, b, c)

            block_cyclic_2D_scatter_worker(world_comm, Mx, Py, mc, pc, c, 333)

            termination_flag[] = MPI.Recv(Bool, world_comm; source=root, tag = 444)
        end

    end

end
