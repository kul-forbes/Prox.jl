export IndGraph

"""
**Indicator of an operator graph**

    IndGraph(A)

For matrix `A` (dense or sparse) returns the indicator function of the set
```math
S = \\{(x, y) : Ax = y\\}.
```

The evaluation of `prox!` uses direct methods based on LDLt (LL for dense cases) matrix factorization and backsolve.

The main method for `prox!` of `IndGraph` has the signature `prox!(x, y, f, c, d, gamma=1.0)`.
In addition the method `prox!(v, f, w)` is defined with `v` being the concatenation of `x, y`, and `w` --  concatenated input.

The `gamma` could be passed as the last argument, but note that it does not affect anything in calculations.
"""

abstract type IndGraph <: ProximableFunction end

function IndGraph(A::AbstractArray{T,2}) where {T <: RealOrComplex}
  if issparse(A)
    IndGraphSparse(A)
  elseif size(A, 1) > size(A, 2)
    IndGraphSkinny(A)
  else
    IndGraphFat(A)
  end
end

is_convex(f::IndGraph) = true
is_set(f::IndGraph) = true
is_cone(f::IndGraph) = true

IndGraph(a::AbstractArray{T,1}) where {T <: RealOrComplex} =
  IndGraph{T}(a')

# fun_name(f::IndGraph) = "Indicator of an operator graph"
fun_dom(f::IndGraph) = "AbstractArray{Real,1}, AbstractArray{Complex,1}"
fun_expr(f::IndGraph) = "x,y ↦ 0 if Ax = y, +∞ otherwise"
fun_params(f::IndGraph) =
  string( "A = ", typeof(f.A), " of size ", size(f.A))

# Additional signatures
function splitinput(f::IndGraph, xy::AbstractVector{T}) where
    {T <: RealOrComplex}
  @assert length(xy) == f.m + f.n
  x = view(xy, 1:f.n)
  y = view(xy, (f.n + 1):(f.n + f.m))
  return x, y
end

function prox!(
    xy::AbstractVector{T},
    f::IndGraph,
    cd::AbstractVector{T},
    gamma=1.0) where
  {T<:RealOrComplex}
 x, y = splitinput(f, xy)
 c, d = splitinput(f, cd)
 prox!(x, y, f, c, d)
 return 0.0
end

function prox_naive(
    f::IndGraph,
    cd::AbstractVector{T},
    gamma=1.0) where
  {T<:RealOrComplex}
 c, d = splitinput(f, cd)
 x, y, f = prox_naive(f, c, d, gamma)
 return [x;y], f
end

include("indGraphSparse.jl")
include("indGraphFat.jl")
include("indGraphSkinny.jl")