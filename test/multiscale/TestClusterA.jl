using MPI

MPI.Init()

@computation cluster TestClusterA begin

    using Statistics

    # Define a custom struct
    # This contains the summary statistics (mean, variance, length) of a vector
    struct SummaryStat
        mean::Float64
        var::Float64
        n::Float64
    end

    function SummaryStat(X::AbstractArray)
        m = mean(X)
        v = varm(X,m, corrected=false)
        n = length(X)
        SummaryStat(m,v,n)
    end

    # Define a custom reduction operator
    # this computes the pooled mean, pooled variance and total length
    function pool(S1::SummaryStat, S2::SummaryStat)
        n = S1.n + S2.n
        m = (S1.mean*S1.n + S2.mean*S2.n) / n
        v = (S1.n * (S1.var + S1.mean * (S1.mean-m)) +
            S2.n * (S2.var + S2.mean * (S2.mean-m)))/n
        SummaryStat(m,v,n)
    end

    @unit master begin

        using MPI

        const comm = MPI.COMM_WORLD
        const root = topology[:master][]

        function perform()
            @info "begin perform master"

            MPI.Barrier(comm)

            X = randn(10,3) .* [1,3,7]'

            # Perform a scalar reduction
            summ = MPI.Reduce(SummaryStat(X), pool, root, comm)
            @show summ.var

            col_summ = MPI.Reduce(mapslices(SummaryStat,X,dims=1), pool, root, comm)
            col_var = map(summ -> summ.var, col_summ)

            return col_var

        end

    end

    @unit parallel count = S slave begin

        using MPI, Statistics

        @info "begin perform slave"

        const comm = MPI.COMM_WORLD
        const root = topology[:master][1]

        function perform()
    
            X = randn(10,3) .* [1,3,7]'
            
            # Perform a scalar reduction
            MPI.Reduce(SummaryStat(X), pool, root, comm)
            MPI.Reduce(mapslices(SummaryStat,X,dims=1), pool, root, comm)

        end

        while true
            MPI.Barrier(comm)
            perform()
        end

    end

end

#MPI.Finalize()