@computation remotecall GEMM_distributed begin

    using Distributed

    a = Ref{Matrix}() 
    b = Ref{Matrix}()

    function setB(b_)
        b[] = b_
    end

    function setA(a_)
        a[] = a_
    end

    function myreduce!(sendbuf; root = 0)
        return copy(sendbuf)
    end

    function reduce(X, Y, nblks, i, irow, jcol, pc, c, c_prime)

        M = size(c_prime, 1)
    
        for j in 0:nblks-1
            root = mod(i + irow, X)  + j*X
            if jcol == mod(root, Y)
               c_prime[1:M, (j*pc+1):((j+1)*pc)] += c[1:M, (div(root,Y)*pc+1):((1+div(root,Y))*pc)]
            end

            sendbuf = c_prime[1:M, (j*pc+1):((1+j)*pc)]
            recvbuf = myreduce!(sendbuf; root = mod(root, Y))
            if (jcol == mod(root,Y))
                c[1:M, (div(root,Y)*pc+1):((1+div(root,Y))*pc)] = recvbuf
            end
        end
    
    end
    
    function shift(X, Y, irow, jcol, b)
    
        next_irow = irow == X - 1 ? 0 : irow + 1
        next_rank = next_irow * Y + jcol + minimum(workers())
                
        @info "shift irow=$irow next_irow=$next_irow jcol=$jcol rank=$(myid()) next_rank=$next_rank"

        remotecall_wait(setB, next_rank, b)

    end
    
    
    @unit parallel gemm begin

        @inner GEMM_threads_entry

        function multiply!(X, Y, pb, pc, alpha, beta, a_, b_, c)
    
            setA(a_) 
            setB(b_) 

            first = minimum(workers())
            rank = myid() - first 
        
            irow = div(rank, Y)
            jcol = mod(rank, Y)
        
            M  = size(a[],1)
            Px = size(b[],1)
        
            nblks = div(size(b[], 1), pb)
        
            c_prime = zeros(M, Px)
        
            for i in 1:X

                GEMM_threads_entry.multiply!(alpha, beta, a[], b[], c_prime)

                # reduce
                reduce(X, Y, nblks, i, irow, jcol, pc, c, c_prime)

                # shift
                shift(X, Y, irow, jcol, b[])
        
                c_prime .= 0.0
            end
        
        end

    end

end