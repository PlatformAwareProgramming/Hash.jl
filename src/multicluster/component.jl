# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

abstract type Multicluster <: AnyLevel end
level_type(::Val{:multicluster}) = Multicluster

start_index(::Type{Multicluster}) = 1

function determine_current_args(::Type{Multicluster}, ::Val{id}, ::Val{true}, block) where id
    @info "determine_current_args 000"
    current_args = read("placement", String)
 #   for w in workers()
 #       @info "send placement $(current_args) to $w"
 #       @spawnat w recv_current_args2(current_args)
 #   end
    return current_args
end

function determine_current_args(::Type{Multicluster}, ::Val{id}, ::Val{lt}, block) where {id, lt}
    nothing
end

#=
current_args = Ref{String}()

wait_current_args = Ref{Threads.Condition}(Threads.Condition())
wait_current_args_flag = Ref{Bool}(false)

function recv_current_args2(c)
    @info "recv_current_args $c"

    current_args[] = c
    if !MPI.Initialized()
        MPI.Init()
    end
    mpi_rank = MPI.Comm_rank(MPI.COMM_WORLD)
    @assert mpi_rank == 0

    lock(wait_current_args[]) do 
        wait_current_args_flag[] = true
        notify(wait_current_args[])
    end

    @info "SEND PLACEMENT BEGIN (rank = $mpi_rank) : $(current_args[])"
    aaa = 999
    MPI.bcast(aaa, 0, MPI.COMM_WORLD)
    MPI.bcast(c, 0, MPI.COMM_WORLD)
    @info "SEND PLACEMENT END"
end

function determine_current_args(::Type{Multicluster}, ::Val{id}, ::Val{lt}, block) where {id, lt}
#    nothing
    @info "determine_current_args 111 id=$id lt=$lt" 

    if !MPI.Initialized() 
        MPI.Init()
    end
    mpi_rank = MPI.Comm_rank(MPI.COMM_WORLD)
    if (mpi_rank == 0)
       lock(wait_current_args[]) do 
           while (!wait_current_args_flag[])
               wait(wait_current_args[])
           end
           wait_current_args_flag[] = false
       end
    else
        @info "RECEIVED PLACEMENT BEGIN aaa (rank = $mpi_rank)"
        aaa = 0
        MPI.bcast(aaa, 0, MPI.COMM_WORLD)
        @info "aaa = $aaa"
        placement = nothing
        MPI.bcast(placement, 0, MPI.COMM_WORLD)
        current_args[] = placement
        @info "RECEIVED PLACEMENT END : $(current_args[])"
    end

    return current_args[]
end
=#