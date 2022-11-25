
# https://bjack205.github.io/tutorial/2021/07/16/julia_package_setup.html

module Hash 

#    using Distributed

    using MPI
    MPI.Init()
    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(comm)
    comm_size = MPI.Comm_size(comm)

    placement = Ref{Any}(Dict())
    placement_inv = Ref{Any}(Dict())
    
    function unit_macro(flag, uname, block, global_uids, is_parallel)

        @assert block.head == :block    
        
        @info "unit $uname $global_uids"

        l = Vector()
        for (k,v) in global_uids            
            for j in v 
                push!(l, j)
            end
        end
        
        sort!(l)
        
        d = Dict()
        for i in 1:length(l)
            d[l[i]] = i
        end

        local_uids = Dict()
        for (k,v) in global_uids
            local_uids[k] = Vector()
            for j in v 
                push!(local_uids[k], d[j])
            end
        end
            
        unit_uids = get(global_uids, uname, [])    
        idx = indexin(rank#=Main.myid()=#, unit_uids)
        if (!isnothing(idx[1]))
            insert!(block.args, 1, :(global_topology = $global_uids)) # global_topology
            insert!(block.args, 1, :(local_topology = $local_uids))   # local_topology
            insert!(block.args, 1, :(unit_idx = $(idx[1])))           # unit_idx
            insert!(block.args, 1, Meta.parse("using $(repeat(".",current_level[]*2+1))Hash"))
            return esc(Expr(:module, flag, uname, block))
        else
            return nothing
        end
    end

#    macro unit(uname, block, uids)
    macro unit(mod, uids)

        @assert mod.head == :module

        flag  = mod.args[1]
        uname = mod.args[2]
        block = mod.args[3]

        unit_macro(flag, uname, block, uids, false)

    end
   
#    macro unit(modifier, uname, block, uids)
    macro unit(modifier, mod, uids)

        @assert mod.head == :module
        
        flag  = mod.args[1]
        uname = mod.args[2]
        block = mod.args[3]

        @assert modifier == :parallel || (modifier == :single && haskey(uids,uname) && length(uids[uname]) == 1)

        return unit_macro(flag, uname, block, uids, modifier == :parallel)

    end
   
    function collect_slices(block)
    
        @assert block.head == :block
        
        r = Dict()
        
        uname = nothing
        for st in block.args
            if (typeof(st) == Expr && st.head == :macrocall && !isempty(st.args) && string(st.args[1]) == "@unit")
               for st2 in st.args[2:length(st.args)]
                    if (typeof(st2)==Expr && st2.head==:module)
                        uname = st2.args[2]
                        for st3 in st2.args[3].args
                            if (typeof(st3) == Expr && st3.head == :macrocall && !isempty(st3.args) && string(st3.args[1]) == "@slice")
                                for st4 in st3.args[2:length(st3.args)]
                                    if typeof(st4) == Expr && st4.head == :.
                                       cname = st4.args[1]
                                       sname = st4.args[2] 
                                       l = get(r,cname,Vector())
                                       push!(l,(sname,uname))
                                       r[cname] = l
                                    end
                                end
                            end
                        end
                        break
                    end
                end
            end
        end
        
        return r
    end
   
    has_placement = Condition()
    has_placement_flag = Ref{Bool}(false)
   
    function calculate_placement(main_placement::AbstractArray{String})
   
        empty!(placement[])
        empty!(placement_inv[])
   
        for l in main_placement
           v = split(l," ")
           id = parse(Int64,v[1])
           pr = Symbol(v[2])
           placement[][id] = pr           
           w = get(placement_inv[],pr,Vector())
           push!(w,id)
           placement_inv[][pr] = w
        end    
        
        has_placement_flag[] = true
        notify(has_placement)
        
    end
    
    function calculate_placement(::Val{0})
                
        main_placement = if isempty(current_args[]) 
                            p = readlines("placement")
                            #=for w in workers()
                                Main.@spawnat w calculate_placement(p)
                            end=#   
                            for w in 1:comm_size-1
                                MPI.send(p, comm; dest=w, tag=99)
                            end
                            p
                         else
                            current_args[]
                         end
        
        calculate_placement(main_placement)        
        
        while !has_placement_flag[]
            wait(has_placement)   
        end 

    end

    function calculate_placement(::Any)
    
#=        if (!isempty(current_args[]))
           calculate_placement(current_args[]) 
        end =#
        
        if (isempty(current_args[]))
            current_args[] = MPI.recv(comm; source=0, tag=99)
        end 
        
        calculate_placement(current_args[]) 
                
        while !has_placement_flag[]
            wait(has_placement)    
        end
        
    end
    
    args_dict = Ref{Dict{Symbol,Vector{String}}}(Dict())
     
    function insert_unit_uids(block)
    
        @assert (block.head == :block)
        
        for st in block.args
            if (typeof(st) == Expr && st.head == :macrocall && !isempty(st.args) && string(st.args[1]) == "@unit")            
                for st2 in st.args[2:length(st.args)]
                    if (typeof(st2)==Expr && st2.head==:module)
                        uname = st2.args[2]
                        push!(st.args, copy(placement_inv[]))
                        @info "INSERT ***** $uname -- $(placement_inv[])"
                        break
                    end
                end
            end
        end
                   
    end
    
    function collect_inner_components(block)
    
        @assert (block.head == :block)
        
        ics = Vector()
        for st in block.args
            if (typeof(st) == Expr && st.head == :macrocall && !isempty(st.args) && string(st.args[1]) in ["@inner"])            
                for st2 in st.args[2:length(st.args)]
                    if typeof(st2) == Symbol 
                        push!(ics, st2)
                    end
                end
            end
        end
        
        return ics

    end
    
    level_dict = Ref{Dict{Symbol,Int}}(Dict())
    
    current_level = Ref{Int}(1)
    
    macro connector(mod)
        component_macro(mod.args[2], mod.args[3], false)
    end
    
    macro computation(mod)
        component_macro(mod.args[2], mod.args[3], false)
    end
    
    macro application(mod)
        component_macro(mod.args[2], mod.args[3], true)
    end
        
    function component_macro(cname, block, isapp)
        return isapp ? esc(:(#=@everywhere =#Hash.@component_($cname, $block))) : esc(:(Hash.@component_($cname, $block)))
    end    
    
    macro component_(cname, block)

        @info "THE LEVEL OF $cname is $(current_level[])"

        calculate_placement(Val(rank#=Main.myid()=#))
        @info "PLACEMENT OF $cname : placement = $(placement[]), placement_inv = $(placement_inv[])"
    
        ss = collect_slices(block)
        
        for (cname, us) in ss
            l = Vector()
            for (sname,uname) in us
                sname_string = string(sname)
                sname_string = sname_string[2:length(sname_string)]

                for id in placement_inv[][uname]
                    push!(l,"$id $sname_string")
                end
            end
            args_dict[][cname] = l
        end 
        
        inner_components = collect_inner_components(block)
        for inner_cname in inner_components
            level_dict[][inner_cname] = current_level[] + 1
        end
       
        insert_unit_uids(block)

        insert!(block.args, 1, Meta.parse("using $(repeat(".",current_level[]*2))Hash"))

        @info "$cname ---  $(args_dict[])"  
        return esc(Expr(:module, true, cname, block))
    
    end
    
    current_args = Ref{Vector{String}}(Vector())
    
    function inner_component(c)    
        current_args[] = args_dict[][c]     
        current_level[] = level_dict[][c]
        cname = "$(string(c)).jl"
        @info "CURRENT ARGS for $cname is $(current_args[])"
        return esc(:(include($cname)))        
    end

    macro inner(c)    
        inner_component(c)
    end
    
    unquotenode(s) = Symbol(string(s)[2:length(string(s))])
    
    macro slice(s)
        return esc(Expr(:import, Expr(:., :., :., s.args[1], unquotenode(s.args[2]))))
    end   
   
    macro slice(s,as,b)
        return esc(Expr(:import, Expr(as, Expr(:., :., :., s.args[1], unquotenode(s.args[2])), b)))
    end   
    
    export @application, @connector, @computation, @inner, @unit, @slice
end # module Hash
