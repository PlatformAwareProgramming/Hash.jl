@application multicluster GEMM_0 begin
    
    @unit master begin
        
    end

    @inner GEMM_0
    
    @unit parallel worker begin
        @slice GEMM_0.gemm
       
        gemm.multiply()

    end 

end