@component messagepassing GEMM_1_entry begin
    
    @unit master begin
    
    end

    @inner GEMM_1

    @unit worker begin
        @slice GEMM_1.gemm
        
        gemm.multiply()

    end

end
