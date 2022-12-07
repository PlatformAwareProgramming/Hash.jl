
# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

abstract type AnyLevel end
abstract type Multicluster <: AnyLevel end
abstract type Cluster <: Multicluster end
abstract type Manycore <: Cluster end

level_type(::Val{:multicluster}) = Multicluster
level_type(::Val{:cluster}) = Cluster
level_type(::Val{:manycore}) = Manycore