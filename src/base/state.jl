# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

args_dict = Ref{Dict{String,Vector{String}}}(Dict("Main" => Vector()))
current_args = Ref{Vector{String}}(Vector())

current_depth = Ref{Int}(0)

placement = Ref{Any}(Dict())
placement_inv = Ref{Any}(Dict())

has_placement = Condition()
has_placement_flag = Ref{Bool}(false)

components = Ref{Vector{String}}(Vector())
push!(components[], "Main")

current_component() = components[][1]
parent_component() = components[][2]

level_dict = Ref{Dict{String,Type}}(Dict("Main" => Cluster))    
current_level = Ref{Type}(Cluster)

enclosing_unit = Ref{Union{Symbol,Nothing}}(nothing)
function reset_enclosing_unit()
    enclosing_unit[] = nothing
end

myrank(::Type{<:Multicluster}) = myid() 
myrank(::Type{<:Cluster}) = rank
#myrank(::Type{<:Manycore}) = 1

function pushComponent(cname)
    pushfirst!(components[], cname)
 #   @info "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%555 PUSH $(args_dict[]) ---- cname = $cname"
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
