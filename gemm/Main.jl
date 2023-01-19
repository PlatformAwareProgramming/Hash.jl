
include("GEMM_mpi_entry.jl")

import .GEMM_mpi_entry

if GEMM_mpi_entry.unit_name == :master

    Mg = 80
    Ng = 180
    Pg = 120
    X  = 2
    Y  = 3
    ma = 20
    n  = 20
    pb = 20
    mc = 20
    pc = 20
    
    a = ones(Mg, Ng)
    b = ones(Pg, Ng)
    c = zeros(Mg, Pg)

    GEMM_mpi_entry.multiply!(X, Y, ma, n, pb, mc, pc, 1.0, 1.0, a, b, c)
    @info sum(c), c[1,1]

    @info c

    GEMM_mpi_entry.finish()

    stop()
end




