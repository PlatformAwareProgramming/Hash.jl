using Hash
using MPI

function stop()
end

MPI.Init()

@computation messagepassing GEMM_mpi_entry begin

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

    function block_cyclic_2D_scatter_worker(comm, X, Y, M, N, m, n, a, tag)
        for i in 1:m:M
            for j in 1:n:N
                MPI.Send(a[i:i+m-1, j:j+n-1], comm; dest = 0, tag = tag)
            end
        end
    end

    function block_cyclic_2D_gather_worker(comm, X, Y, M, N, m, n, a, tag)
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

        function multiply!(X, Y, M, N, P, ma, n, pb, mc, pc, alpha, beta, a, b, c)

            world_comm = MPI.COMM_WORLD
            world_group = MPI.Comm_group(world_comm)
            workers_group = MPI.Group_excl(world_group, Int32[0])
            MPI.Comm_create(world_comm, workers_group)

            root = topology[:master][1]
            MPI.bcast((X, Y, M, N, P, ma, n, pb, mc, pc, alpha, beta), root, world_comm)

            @info "$unit_idx: SCATTER a - master - begin"
            block_cyclic_2D_scatter_master(world_comm, X, Y, M, N, ma, n, a, 111)
            @info "$unit_idx: SCATTER a - master - end"
            
            @info "$unit_idx: SCATTER b - master - begin"
            block_cyclic_2D_scatter_master(world_comm, X, Y, P, N, pb, n, b, 222)
            @info "$unit_idx: SCATTER b - master - end"

            @info "$unit_idx: GATHER c - master - begin"
            block_cyclic_2D_gather_master(world_comm, X, Y, M, P, mc, pc, c, 333)
            @info "$unit_idx: GATHER c - master - end"

            return c
        end

    end

    @inner GEMM_mpi

    @unit parallel count=N worker begin

        using MPI

        @info "======>>>> WORKER unit_idx = $unit_idx, topology = $topology, local_topology = $local_topology"

        @slice GEMM_mpi.gemm

        world_comm = MPI.COMM_WORLD
        world_group = MPI.Comm_group(world_comm)
        workers_group = MPI.Group_excl(world_group, Int32[0])
        workers_comm = MPI.Comm_create(world_comm, workers_group)

        root = topology[:master][1]
        (X, Y, M, N, P, ma, n, pb, mc, pc, alpha, beta) = MPI.bcast(nothing, world_comm)

        @info "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% $((X, Y, M, N, P, ma, n, pb, mc, pc))"

        Mx = div(M, X)
        Ny = div(N, Y)
        Px = div(P, X)
        Py = div(P, Y)
        
        a = zeros(Mx, Ny)
        b = zeros(Px, Ny)
        c = zeros(Mx, Py)

        @info "$unit_idx: GATHER a - worker - begin"
        block_cyclic_2D_gather_worker(world_comm, X, Y, Mx, Ny, ma, n, a, 111)
        @info "$unit_idx: GATHER a - worker - end"

        @info "$unit_idx: GATHER b - worker - begin"
        block_cyclic_2D_gather_worker(world_comm, X, Y, Px, Ny, pb, n, b, 222)
        @info "$unit_idx: GATHER b - worker - end"

        gemm.multiply!(workers_comm, X, Y, pb, pc, alpha, beta, a, b, c)

        @info "$unit_idx: SCATTER c -worker - begin"
        block_cyclic_2D_scatter_worker(world_comm, X, Y, Mx, Py, mc, pc, c, 333)
        @info "$unit_idx: SCATTER c -worker - end"

        function multiply!(X, Y, M, N, P, ma, n, pb, mc, pc, a, b, c) nothing end
    end

end
