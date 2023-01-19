# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

topLevel = Ref{Type}(AnyLevel)
function setTopLevel(level)
    topLevel[] = level
    @info "SET LEVEL TOP $(topLevel[])"
end

getTopLevel() = topLevel[]

args_dict = Ref{Dict{String,String}}(Dict())
current_args = Ref{String}()

current_depth = Ref{Int}(0)

placement_inv = Ref{Any}(Dict())

has_placement = Threads.Condition()
has_placement_flag = Ref{Bool}(false)

components = Ref{Vector{String}}(Vector())
push!(components[], "Main")

current_component() = components[][1]
parent_component() = components[][2]

level_dict = Ref{Dict{String,Type}}(Dict())    
current_level = Ref{Type}(AnyLevel)

unit_topology = Dict{String, Dict{Symbol, Vector{Int}}}()
unit_local_topology = Dict{String,Dict{Symbol, Vector{Int}}}()

function setTopology(topology, local_topology)
    unit_topology[current_component()] = topology
    unit_local_topology[current_component()] = local_topology
end

function getTopology()
    return unit_topology[current_component()]
end

function getLocalTopology()
    return unit_local_topology[current_component()]
end

enclosing_unit = Ref{Union{Symbol,Nothing}}(nothing)
function reset_enclosing_unit()
    enclosing_unit[] = nothing
end

function pushComponent(cname)
    pushfirst!(components[], cname)
    current_args[] = args_dict[][current_component()]
    current_depth[] += 1 # depth_dict[][current_component()]  
    current_level[] = level_dict[][current_component()]  
    return current_component()
end

function popComponent()
    deleteat!(components[],1)
    current_args[] = args_dict[][current_component()]
    current_depth[] -= 1 # depth_dict[][current_component()]    
    current_level[] = level_dict[][current_component()]
end

function parentComponent()
    SubString(current_component(), 1:findlast(".", current_component()).stop-1)
end

function is_nonmacro_command(command)
    if typeof(command) == Expr && command.head == :macrocall && command.args[1] in [Symbol("@unit"), Symbol("@inner"), Symbol("@slice")]
        return true
    end
    return false
end