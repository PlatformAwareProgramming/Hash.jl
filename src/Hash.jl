
# https://bjack205.github.io/tutorial/2021/07/16/julia_package_setup.html

module Hash 

    using Distributed
    using MulticlusterManager
    using MPI
    using CpuId

    include("utils.jl")
    include("base/levels.jl")
    include("base/state.jl")
    include("base/component.jl")
    include("multicluster/component.jl")
    include("cluster/remotecall/component.jl")
    include("cluster/component.jl")
    include("manycore/component.jl")
    include("base/inner.jl")
    include("base/unit.jl")
    include("multicluster/unit.jl")
    include("cluster/remotecall/unit.jl")
    include("cluster/unit.jl")
    include("manycore/unit.jl")
    include("base/slice.jl")
    include("multicluster/slice.jl")
    include("cluster/remotecall/slice.jl")
    include("cluster/slice.jl")
    include("manycore/slice.jl")
    include("multicluster/launch.jl")
    include("multicluster/remotecall.jl")
    include("multicluster/synchronize_units.jl")

    function __init__()
        if "mpi" in ARGS
            mpibcast_rank()
            setTopLevel(Cluster)
        end
    end

    export @application, @connector, @computation, @inner, @unit, @slice, @cluster, @launch, @remotecall, @remotecall_fetch, notify_unit, wait_unit
    
end # module Hash
