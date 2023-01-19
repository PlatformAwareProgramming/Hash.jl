# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

abstract type Manycore <:  AnyLevel end
level_type(::Val{:manycore}) = Manycore
level_depth(::Type{Manycore}) = 2

start_index(::Type{Manycore}) = 0

total_count = Ref{Int}(0)

placement_expr(::Type{Manycore}, expr) = :(let N = $(Threads.nthreads()); P = $(CpuId.cpunodes()) ; T = $(CpuId.cputhreads()); C = CpuId.cpucores(); $expr end)

function determine_current_args(level::Type{Manycore}, id, ::Val{true}, block) 

    units = collect_units(level, block)

    total_count[], ts = distribute_units(units)

    l = ""
    for i in 0:length(ts)-1
        l = l * "$(ts[i+1])\n"
    end

    current_args[] = l
    return l
end

function determine_current_args(::Type{Manycore}, id, ::Val{false}, block)
    nothing
end

#function insertAdditionalStatements(::Type{Manycore}, ::Val{true}, block)
    #pushfirst!(block.args, Meta.parse("function notify_unit_finished() Threads.atomic_add!(wait_unit_threads_counter, 1); if $(total_count[]) <= wait_unit_threads_counter[] lock(wait_unit_threads[]) do \n notify(wait_unit_threads[]) end end end"))
    #pushfirst!(block.args, :(wait_unit_threads_counter = Threads.Atomic{Int}(0)))
    #pushfirst!(block.args, :(wait_unit_threads = Ref{Threads.Condition}(Threads.Condition())))
    #push!(block.args, Meta.parse("lock(wait_unit_threads[]) do \n while wait_unit_threads_counter[]<$(total_count[])  wait(wait_unit_threads[]) end end"))
#    insertAdditionalStatements(AnyLevel, Val(true), block)
#end

