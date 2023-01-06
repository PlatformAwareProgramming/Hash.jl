
using MPI

function local_multiply(a, b, c)    
    M = size(a,1)
    P = size(b,1)
    N = size(a,2); @assert N == size(b,2)

    for j in 1:P, i in 1:M, k in 1:N
        c[i,j] += a[i,k] * b[j,k]
    end

end

function reduce(comm, X, Y, nblks, i, irow, jcol, pc, c, c_prime)

    M = size(c_prime, 1)

    for j in 0:nblks-1
        root = mod(i + irow, X)  + j*X
        if jcol == mod(root, Y)
           c_prime[1:M, (j*pc+1):((j+1)*pc)] += c[1:M, (div(root,Y)*pc+1):((1+div(root,Y))*pc)]
        end
        #@info "c_prime[1:$M,$(j*pc+1):$((j+1)*pc)] += c[1:$M,$(div(root,Y)*pc+1):$((div(root,Y)+1)*pc)]"
        sendbuf = c_prime[1:M, (j*pc+1):((1+j)*pc)]
        recvbuf = zeros(M, pc)
        MPI.Reduce!(sendbuf, recvbuf, MPI.SUM, comm; root = mod(root, Y))
        if (jcol == mod(root,Y))
            c[1:M, (div(root,Y)*pc+1):((1+div(root,Y))*pc)] = recvbuf
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

function multiply(comm, X, Y, pb, pc, a, b, c)

    rank = MPI.Comm_rank(comm)

    irow = div(rank, Y)
    jcol = mod(rank, Y) 
    row_comm = MPI.Comm_split(comm, irow, jcol);
    col_comm = MPI.Comm_split(comm, jcol, irow);

    M  = size(a,1)
    Px = size(b,1)

    nblks = div(size(b, 1), pb)

    c_prime = zeros(M, Px)

    for i in 1:X

        local_multiply(a, b, c_prime)    
        # reduce
        reduce(row_comm, X, Y, nblks, i, irow, jcol, pc, c, c_prime)
        # shift
        shift(col_comm, X, irow, b)

        c_prime .= 0.0
    end

end

function main()

    MPI.Init() 

    comm = MPI.COMM_WORLD

    Mg = parse(Int64, ARGS[1])
    Ng = parse(Int64, ARGS[2])
    Pg = parse(Int64, ARGS[3])
    X  = parse(Int64, ARGS[4])
    Y  = parse(Int64, ARGS[5])
    pb = parse(Int64, ARGS[6])
    pc = parse(Int64, ARGS[7])

    M  = div(Mg, X)       
    N  = div(Ng, Y)        
    Px = div(Pg, X)        
    Py = div(Pg, Y)

    @info "M=$M, N=$N, Px=$Px, Py=$Py"

    # X, Y: número de linhas e colunas de processos
    # M, N, P: dimensões das matrizes A, B e C 
    # A local tem dimensões M/X e N/Y, com blocos ma x n
    # B local (transposta) tem dimensões P/X e N/Y, com blocos pb x n

    a = ones(M, N)
    b = ones(Px, N)
    c = zeros(M, Py)

    multiply(comm, X, Y, pb, pc, a, b, c)

    @info c

    @info "finish"

    MPI.Finalize()

end

main()