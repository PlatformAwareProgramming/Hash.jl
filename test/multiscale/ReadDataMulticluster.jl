using Hash
 
@connector multicluster module ReadDataMulticluster

    @unit single module producer
        
        function produce()
            @info "PRODUCE!"
        end
        
    end

    @unit parallel module consumer
        
        @inner MakeSomething as MK

        function consume()
            @info "CONSUME!"
        end

    end
    
end

