# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

using StaticArrays

function createArrays(::Val{size}) where size
	local_visited     = MArray{Tuple{size+1},Int64}(undef)
	local_permutation = MArray{Tuple{size+1},Int64}(undef)

	local_visited     .= 0
	local_permutation .= 0

    local_visited, local_permutation
end

# verifies whether a given solution/incomplete solution is feasible
function valid_configuration(board, roll)

	@inbounds begin
		for i=2:roll-1
			if (board[i] == board[roll])
				return false
			end
		end

		ld = board[roll]
		rd = board[roll]

		for j=(roll-1):-1:2
			ld -= 1
			rd += 1
			if (board[j] == ld || board[j] == rd)
				return false
			end
		end
	end

	return true
end ##queens_is_valid_conf

macro tree_explorer(name, depth_initial, depth_solution, depth_break, initial_solution, action_solution, returned_solution) 

	:(function $name(::Val{size}, ::Val{cutoff_depth}, local_visited, local_permutation) where {size, cutoff_depth}

		@inbounds begin
			__VOID__     = 0
			__VISITED__    = 1
			__N_VISITED__   = 0

			depth = $depth_initial
			tree_size = 0
			$initial_solution	

			while true
				local_permutation[depth] = local_permutation[depth] + 1

				if local_permutation[depth] == size + 1
					local_permutation[depth] = __VOID__
				elseif (local_visited[local_permutation[depth]] == 0 && valid_configuration(local_permutation, depth))
					local_visited[local_permutation[depth]] = __VISITED__
					depth += 1
					tree_size += 1
					depth == $depth_solution ? $action_solution : continue
				else
					continue
				end

				depth -= 1
				local_visited[local_permutation[depth]] = __N_VISITED__

				depth >= $depth_break || break
			end
		end

		return $returned_solution, tree_size
	end)
end