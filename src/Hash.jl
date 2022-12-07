
# https://bjack205.github.io/tutorial/2021/07/16/julia_package_setup.html

module Hash 

    using Distributed
    using MPI

    function __init__()
      MPI.Init()
      global comm = #= nothing =# MPI.COMM_WORLD
      global rank = #= nothing =# MPI.Comm_rank(comm)
      global comm_size = #= nothing =# MPI.Comm_size(comm)
    end

    include("utils.jl")
    include("base/levels.jl")
    include("base/state.jl")
    include("base/component.jl")
    include("multicluster/component.jl")
    include("cluster/component.jl")
    include("manycore/component.jl")
    include("base/inner.jl")
    include("base/unit.jl")
    include("multicluster/unit.jl")
    include("cluster/unit.jl")
    include("manycore/unit.jl")
    include("base/slice.jl")
 
    export @application, @connector, @computation, @inner, @unit, @slice
    
end # module Hash
