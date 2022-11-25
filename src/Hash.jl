
# https://bjack205.github.io/tutorial/2021/07/16/julia_package_setup.html

module Hash 

    using MPI

    function __init__()
        MPI.Init()
        global comm = MPI.COMM_WORLD
        global rank = MPI.Comm_rank(comm)
        global comm_size = MPI.Comm_size(comm)
    end

    include("utils.jl")
    include("state.jl")
    include("component.jl")
    include("inner.jl")
    include("unit.jl")
    include("slice.jl")

    export @application, @connector, @computation, @inner, @unit, @slice
    
end # module Hash
