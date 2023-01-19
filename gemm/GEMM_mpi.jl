@computation cluster GEMM_mpi begin
    
    using MPI

    function reduce(comm, X, Y, nblks, i, irow, jcol, pc, c, c_prime)

        M = size(c_prime, 1)
    
        for j in 0:nblks-1
            root = mod(i + irow, X)  + j*X
            if jcol == mod(root, Y)
               c_prime[1:M, (j*pc+1):((j+1)*pc)] += c[1:M, (div(root,Y)*pc+1):((1+div(root,Y))*pc)]
            end
            sendbuf = c_prime[1:M, (j*pc+1):((1+j)*pc)]
            recvbuf = zeros(M, pc)
            MPI.Reduce!(sendbuf, recvbuf, MPI.SUM, comm; root = mod(root, Y))
            if (jcol == mod(root,Y))
                c[1:M, (div(root,Y)*pc+1):((1+div(root,Y))*pc)] += recvbuf
            end
        end
    
    end
    
    function shift(comm, X, irow, b)
    
        r = irow == X - 1 ? 0 : irow + 1
        s = irow == 0 ? X - 1 : irow -1
    
        sreq = MPI.Isend(b, comm; dest=r)
        rreq = MPI.Irecv!(b, comm; source=s)
        MPI.Waitall([sreq, rreq])
    
    end
    
    
    @unit parallel gemm begin

        @inner GEMM_threads_entry

        function multiply!(comm, X, Y, pb, pc, alpha, beta, a, b, c)
    
            rank = MPI.Comm_rank(comm)
        
            irow = div(rank, Y)
            jcol = mod(rank, Y)
            row_comm = MPI.Comm_split(comm, irow, jcol)
            col_comm = MPI.Comm_split(comm, jcol, irow)
        
            M  = size(a,1)
            Px = size(b,1)
        
            nblks = div(size(b, 1), pb)
        
            c_prime = zeros(M, Px)
        
            for i in 1:X
        
                GEMM_threads_entry.multiply!(alpha, beta, a, b, c_prime)
            
                # reduce
                reduce(row_comm, X, Y, nblks, i, irow, jcol, pc, c, c_prime)

                # shift
                shift(col_comm, X, irow, b)
        
                c_prime .= 0.0
            end
        
        end
    
    end

end