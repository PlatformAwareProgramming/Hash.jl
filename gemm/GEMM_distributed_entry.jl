using Hash
using Distributed

@computation remotecall GEMM_distributed_entry begin

    @unit master begin

        @info "======>>>> unit_idx = $unit_idx, global_topology = $global_topology, local_topology = $local_topology"

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
        
        function multiply!(X, Y, M, N, P, a, b, c)

            reorder_matrix!(X, Y, Mg, Ng, ma, n, a)
            reorder_matrix!(X, Y, Pg, Ng, pb, n, b)

            for row in 0:X-1
                for col in 0:Y-1
                    widx = row * Y + col + 1
                    wpid = global_topology[:worker][widx]                    
                    Mx = div(M, X)
                    Ny = div(N, Y)
                    Px = div(P, X)
                    Py = div(P, Y)
                    rMx = row * Mx
                    rNy = col * Ny
                    rPx = row * Px
                    rPy = col * Py

                    buf = @spawnat wpid multiply(a[rMx:rMx+Mx-1,rNy:rNy+Ny-1], b[rPx:rPx+Px-1,rNy:rNy+Ny-1])
                    
                    c[rMx:rMx+Mx-1,rPy:rPy+Py-1] = buf

                end
            end
        end
    end

    @inner GEMM_distributed

    alpha = 1.0
    beta  = 1.0

    @unit parallel count=W worker begin

        @info "======>>>> M=$M, N=$N, Px=$Px, Py=$Py, unit_idx = $unit_idx, global_topology = $global_topology, local_topology = $local_topology"

        @slice GEMM_distributed.gemm

        function multiply!(X, Y, M, N, a, b)
            Px = div(Pg, X)
            Py = div(Pg, Y)
            
            c = ???

            gemm.multiply(X, Y, pb, pc, alpha, beta, a, b, c)
    
            return c
        end

    end

end
