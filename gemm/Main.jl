using Hash

include("GEMM_mpi_entry.jl")

import .GEMM_mpi_entry

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

M  = div(Mg, X)
N  = div(Ng, Y)

a = ones(Mg, Ng)
b = ones(Pg, Ng)
c = zeros(Mg, Pg)


GEMM_mpi_entry.multiply!(X, Y, Mg, Ng, Pg, ma, n, pb, mc, pc, a, b, c)
