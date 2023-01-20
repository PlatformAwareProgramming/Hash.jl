# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

@tree_explorer(queens_partial_search,
               1,
			   cutoff_depth + 1,
			   2,
			   subproblems_pool = [],
			   push!(subproblems_pool, (copy(local_visited), copy(local_permutation))),
			   subproblems_pool)

#=@tree_explorer(queens_tree_explorer_serial,
               1,
			   size + 1,
			   2, 
			   number_of_solutions = 0,
			   number_of_solutions += 1,
			   number_of_solutions)
=#
@tree_explorer(queens_tree_explorer_parallel,
			   cutoff_depth + 1,
			   size + 1,
			   cutoff_depth + 1,
			   number_of_solutions = 0,
			   number_of_solutions += 1, 
			   number_of_solutions)

function queens_partial_search(size_v::Val{size}, cutoff_depth) where size

	subproblems_pool = []

	local_visited, local_permutation = createArrays(size_v)

	subproblems_pool, tree_size = queens_partial_search(size_v, Val(cutoff_depth), local_visited, local_permutation)

	number_of_subproblems = length(subproblems_pool)

	return subproblems_pool, number_of_subproblems, tree_size

end #queens partial





