# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

abstract type MessagePassing <: Cluster end
level_type(::Val{:messagepassing}) = MessagePassing

start_index(::Type{MessagePassing}) = 0

function placement_expr(::Type{MessagePassing}, expr)
    size = MPI.Comm_size(MPI.COMM_WORLD)
    expr_result = :(let S = $(size-1); $expr end)
    @info "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ placement_expr: $expr_result"
    return expr_result
end

#function determine_current_args(::Type{MessagePassing}, ::Val{0}, ::Val{true}, block)
   # comm = MPI.COMM_WORLD
   # comm_size = MPI.Comm_size(comm)
   # for w in 1:comm_size-1
   #     @info "send placement 1 to $w -- $(current_args[])"
   #     MPI.send(current_args[], comm; dest=w, tag=99)
   # end
#end

function determine_current_args(level::Type{MessagePassing}, ::Val{id}, ::Val{true}, block) where id
    # comm = MPI.COMM_WORLD
    # current_args[] = MPI.recv(comm; source=0, tag=99)
    # @info "RECEIVE PLACEMENT FROM 0 $(current_args[])"

    units = collect_units(level, block)

    total_count[], ts = distribute_units(units)

    l = ""
    for i in 0:length(ts)-1
        l = l * "$(ts[i+1])\n"
    end

    current_args[] = l
end
 
function determine_current_args(::Type{MessagePassing}, ::Val{0}, ::Val{false}, block)
    nothing
end


function determine_current_args(::Type{MessagePassing}, ::Val{id}, ::Val{false}, block) where id
    nothing
end
