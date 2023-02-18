# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------


hosts = Ref{Dict}(Dict())

macro cluster(name, host_addr, binding_addr, n, args...)
    cluster_config(name, host_addr, binding_addr, n, args)
end

function cluster_config(name, host_addr, binding_addr, n, args)
    hosts[][name] = (host_addr, binding_addr, n, args)
    @info hosts[][name]
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
        end
    end

    for t in args
        @assert t.head == :call
        @assert t.args[1] == :(:)
        c = t.args[3]
        (host_addr, binding_addr, n, host_args) = hosts[][c]
        host_addr = split(host_addr,":")[1]

        host_dir = ``
        scp_flags = ``
        for arg in host_args
            if arg.args[1] == :dir
                host_dir = eval(arg.args[2])
            elseif arg.args[1] == :scpflags
                scp_flags = eval(arg.args[2])
            end
        end
        
        cmd = `scp $scp_flags ./placement $host_addr:$host_dir`

        @info cmd
        run(cmd)
    end

    for t in args
        @assert t.head == :call
        @assert t.args[1] == :(:)
        c = t.args[3]
        (host_addr, binding_addr, n, host_args) = hosts[][c]
        if binding_addr != :nothing
            host_addr = "$host_addr $binding_addr"
        end
        addprocs_args = Vector()
        push!(addprocs_args, :addprocs_mpi)
        kwargs = Expr(:parameters, map(t->Expr(:kw,t.args[1],t.args[2]) , host_args)...)
        push!(addprocs_args, kwargs)
        rgargs = :([($host_addr, $app_full, $n, $app_full)])
        push!(addprocs_args, rgargs)
        push!(block_args, Expr(:macrocall, Symbol("@async"), :(), Expr(:call, addprocs_args...)))
    end

    push!(block_args, Expr(:macrocall, Symbol("@async"), :(), :(include($app_full))))

    @info Expr(:macrocall, Symbol("@sync"), nothing, Expr(:block, block_args...))
    esc(Expr(:macrocall, Symbol("@sync"), nothing, Expr(:block, block_args...)))

end