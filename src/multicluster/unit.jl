# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

myrank_ = Ref{Integer}(-1)
myrank_set = Ref{Condition}(Condition())

function setRank(rank)
    myrank_[] = rank
    lock(myrank_set[]) do 
        notify(myrank_set[])        
        @info "NOTIFY RANK !!!!!!!!!!!!!!!!!!!!!!!!!!! $rank" 
    end
end

function mpibcast_rank()
    MPI.Init()
    mpi_rank = MPI.Comm_rank(MPI.COMM_WORLD)
    if mpi_rank == 0
        @info "BROACAST ROOT BEGIN"        
        rank = myrank(Multicluster)
        @info "BROACAST ROOT END $rank"        
    else
        @info "$mpi_rank -- BROACAST WORKER"        
        rank = nothing
    end
    rank = MPI.bcast(rank, 0, MPI.COMM_WORLD)
    @info "$mpi_rank -- BROADCAST $rank"
    setRank(rank)
end


function myrank(::Type{Multicluster}) 
    if "mpi" in ARGS
        lock(myrank_set[]) do 
            while myrank_[] < 0
                @info "WAIT RANK !!!!!!!!!!!!!!!!!!!!!!!!!!!" 
                wait(myrank_set[])
            end    
        end
    else
        myrank_[] = myid()
        @info "MY ID ************* is $(myrank_[])"
    end
    myrank_[]
end

function unit_macro_result(level::Type{Multicluster}, is_level_top, ::Val{uname}, unit_uids, flag, block#=, global_uids, local_uids=#) where uname
    @info "1 **************************** $uname $level $unit_uids $(myrank(level))"
    idx = indexin(myrank(level), unit_uids)
    result = if !isnothing(idx[1])
                pushfirst!(block.args, :(unit_idx = $(idx[1])))           # unit_idx
                push!(block.args, :(Hash.reset_enclosing_unit()))
                @info "$(myrank(level)): ++++++++++++++++++ UNIT $uname of $(current_component()) at level $level"
                #@info  Expr(:module, flag, uname, block)  
                #Expr(:module, flag, uname, block)  
                #@info block
                block
            else
                Hash.reset_enclosing_unit()
                @info "$(myrank(level)): ------------------ UNIT $uname of $(current_component()) at level $level"
                nothing
            end
    return result
end
