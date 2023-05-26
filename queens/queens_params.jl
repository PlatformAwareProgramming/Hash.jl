# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

using CUDA

global const cpu_percentage = Ref{Real}(0.5)

function setCpuPortion(v)
    cpu_percentage[] = v 
 end
 
function getCpuPortion()
    cpu_percentage[]
end
 
global const __BLOCK_SIZE_ = Ref{Integer}(128)

function setBlockSize(v)
    __BLOCK_SIZE_[] = v 
 end
 
function getBlockSize()
    __BLOCK_SIZE_[]
end

function configureHeap()        
    for gpus in  1:length(CUDA.devices())
        @info("Setting heap on device $(gpus-1)");
        device!(gpus-1)
        synchronize()
        CUDA.@check @ccall CUDA.libcudart().cudaDeviceSetLimit(CUDA.cudaLimitMallocHeapSize::CUDA.cudaLimit, 1000000000::Csize_t)::CUDA.cudaError_t
        synchronize()
    end
end

export setCutoffDepth, getCutoffDepth,
       setBlockSize, getBlockSize,
       setCpuPortion, getCpuPortion