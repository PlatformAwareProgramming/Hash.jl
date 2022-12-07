# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function determine_current_args(::Type{Cluster}, ::Val{0}, level_transition, block)
    for w in 1:comm_size-1
        @info "send placement 1 to $w"
        MPI.send(current_args[], comm; dest=w, tag=99)
    end
end

function determine_current_args(::Type{Cluster}, ::Val{id}, level_transition, block) where id
    @info "RECEIVE PLACEMENT FROM 0"
    current_args[] = MPI.recv(comm; source=0, tag=99)
end

