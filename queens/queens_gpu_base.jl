# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

using CUDA

function queens_gpu_subproblems_organizer!(cutoff_depth, num_subproblems, prefixes, controls, starting_point, subproblems)

	for sub in 0:num_subproblems-1
		stride = sub*cutoff_depth
		for j in 1:cutoff_depth
			controls[stride + j] = subproblems[starting_point + sub][1][j] # subproblem_is_visited
			prefixes[stride + j] = subproblems[starting_point + sub][2][j] # subproblem_partial_permutation
		end
	end

end

function gpu_queens_tree_explorer!(size_v::Val{size}, cutoff_depth_v::Val{cutoff_depth}, number_of_subproblems, 
                                   permutation_d, 
                                   controls_d, 
                                   tree_size_d, 
                                   number_of_solutions_d) where {size, cutoff_depth}
	@inbounds begin

		#obs: because the vector begins with 1 I need to use size+1 for N-Queens of size 'size'
		index =  (blockIdx().x - 1) * blockDim().x + threadIdx().x

		if index <= number_of_subproblems
			stride_c = (index-1)*cutoff_depth

			local_visited, local_permutation = createArrays(size_v)

			#@OBS> so... I allocate on CPU memory for the cuda kernel...
			### then I get the values on GPU.
			for j in 1:cutoff_depth
				local_visited[j] = controls_d[stride_c + j]
				local_permutation[j] = permutation_d[stride_c + j]	
			end

			number_of_solutions, tree_size = queens_tree_explorer_parallel(size_v, cutoff_depth_v, local_visited, local_permutation)
			#number_of_solutions, tree_size = queens_tree_explorer_parallel(size_v, cutoff_depth_v, controls_d[stride_c:(stride_c+cutoff_depth)], permutation_d[stride_c:(stride_c+cutoff_depth)])

			number_of_solutions_d[index] = number_of_solutions
			tree_size_d[index] = tree_size
		end #if
	end
return

end #queens tree explorer


function queens_gpu_caller(size, cutoff_depth, number_of_subproblems, starting_point, subproblems)
		
	number_of_solutions = 0
	partial_tree_size = 0

	subpermutation_h = zeros(Int64, cutoff_depth * number_of_subproblems)
	controls_h = zeros(Int64, cutoff_depth * number_of_subproblems)
	number_of_solutions_h = zeros(Int64, number_of_subproblems)
	tree_size_h = zeros(Int64, number_of_subproblems)

	queens_gpu_subproblems_organizer!(cutoff_depth, number_of_subproblems, subpermutation_h, controls_h, starting_point, subproblems)

	#### the subpermutation_d is the memory allocated to keep all subpermutations and the control vectors...
	##### Maybe I could have done it in a smarter way...
	subpermutation_d = CuArray{Int64}(undef, cutoff_depth * number_of_subproblems)
	controls_d       = CuArray{Int64}(undef, cutoff_depth * number_of_subproblems)

	#### Tree size and number of solutions is to get the metrics from the search.
	number_of_solutions_d = CUDA.zeros(Int64, number_of_subproblems)
	tree_size_d = CUDA.zeros(Int64, number_of_subproblems)

	# copy from the CPU to the GPU
	copyto!(subpermutation_d, subpermutation_h)
	# copy from the CPU to the GPU
	copyto!(controls_d, controls_h)

	__BLOCK_SIZE_ = getBlockSize()

	num_blocks = ceil(Int, number_of_subproblems/__BLOCK_SIZE_)

	#@info "device $(device()): threads=$__BLOCK_SIZE_ blocks=$num_blocks"
    @cuda threads=__BLOCK_SIZE_ blocks=num_blocks gpu_queens_tree_explorer!(Val(size), Val(cutoff_depth), number_of_subproblems, subpermutation_d, controls_d, tree_size_d, number_of_solutions_d)

    #from de gpu to the cpu
	copyto!(number_of_solutions_h, number_of_solutions_d)
	#from de gpu to the cpu
	copyto!(tree_size_h, tree_size_d)

	number_of_solutions = sum(number_of_solutions_h)
	partial_tree_size += sum(tree_size_h)

	return number_of_solutions, partial_tree_size
end #caller
