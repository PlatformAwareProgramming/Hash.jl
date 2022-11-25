# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

placement = Ref{Any}(Dict())
placement_inv = Ref{Any}(Dict())

args_dict = Ref{Dict{Symbol,Vector{String}}}(Dict())
     
level_dict = Ref{Dict{Symbol,Int}}(Dict())

current_level = Ref{Int}(1)

current_args = Ref{Vector{String}}(Vector())

has_placement = Condition()
has_placement_flag = Ref{Bool}(false)
