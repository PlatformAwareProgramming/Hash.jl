# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------


hosts = Ref{Dict}(Dict())

macro cluster(name, address, n, args...)
    cluster_config(name, address, n, args)
end


function cluster_config(name, address, n, args)
    hosts[][name] = (address, n, args)
    return hosts[][name]
end

#= 
    * launches each unit of the multicluster application in a specified cluster.
    app: multicluster application name.
    args: pairs (unit, cluster name or list of cluster names).
=#
macro launch(app, args...)
   do_launch(app, args)
end

function do_launch(app, args)

    app_full = "$app.jl"
    block_args = Vector()

    touch("placement")
    open("placement","w") do placement_file
        write(placement_file, "master\n")
        for t in args
            @assert t.head == :call
            @assert t.args[1] == :(:)
            u = t.args[2]
            write(placement_file, "$u\n")
            c = t.args[3]
            (host_addr, n, host_args) = hosts[][c]
            #addprocs_mpi([(host_addr, n, "$app.jl")], [eval(i) for i in host_args]...)
            addprocs_args = Vector()
            push!(addprocs_args, :addprocs_mpi)
            kwargs = Expr(:parameters, map(t->Expr(:kw,t.args[1],t.args[2]) , host_args)...)
            push!(addprocs_args, kwargs)
            rgargs = :([($host_addr, $app_full, $n, $app_full)])
            push!(addprocs_args, rgargs)
            push!(block_args, Expr(:call, addprocs_args...))
        end

        push!(block_args, :(include($app_full)))
    end

    @info Expr(:block, block_args...)
    Expr(:block, block_args...)
end