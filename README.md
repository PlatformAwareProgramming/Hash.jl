# Hash.jl

This is an experimental package for Julia programmers to implement parallel computations aimed at exploiting multi-level parallelism hierarchies. The current supported levels are *multicluster*, *cluster*, and *multicore*, with plans to include the support for accelerators in the near future. 

It is still a proof-of-concept prototype for the concept of a *multiscale parallel component model* called μHash, in which parallel computing concerns at different levels of the parallelism hierarchy of a parallel computing platform are encapsulated in distinct components. 

In a parallel programming language/artifact fully based on μHash, a particular implementation of a parallel computation that exploit multiple levels of the parallelism hierarchy of a parallel computer naturally comprises a set of components. They encapsulate the concerns behind the implementation of the computation for each level, separately. By consequence of such a modularity feature, this language/artifact itself may give support to the best programming abstractions, constructs, and primitives for exploiting efficiently the parallelism at each level, instead of relying on external artifacts (e.g., third-party libraries and frameworks). 

In the current implementation of Hash.jl, using the metaprogramming features of Julia to avoid modifying its compiler or runtime system, components are still compile-time entities (static), and Julia programmers must use the existing programming artifacts of the Julia ecosystem (e.g. Distributed.jl, MPI.jl, FLoops.jl, @threads, @spawn, etc) in order to program for each parallelism level. 

Hash.hl depends on another experimental package, called [MulticlusterManager.jl](https://github.com/PlatformAwareProgramming/MulticlusterManager.jl) in order to enable parallelism at the multicluster level.

Please contact us if you are interested in using this package or contributing to its development.
