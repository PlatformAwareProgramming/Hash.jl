
include("GEMM_distributed_entry.jl")

import .GEMM_distributed_entry

if GEMM_distributed_entry.unit == :master

    Mg = 800
    Ng = 1800
    Pg = 1200
    X  = 2
    Y  = 3
    ma = 200
    n  = 200
    pb = 200
    mc = 200
    pc = 200

    a = ones(Mg, Ng)
    b = ones(Pg, Ng)
    c = zeros(Mg, Pg)

    GEMM_distributed_entry.multiply!(X, Y, Mg, Ng, Pg, ma, n, pb, mc, pc, 1.0, 1.0, a, b, c)
    @info c[1,1]

    stop()
end




