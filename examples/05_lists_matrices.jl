# 05_lists_matrices.jl: lists, vectors and matrices (examples/05 of rewrite),
# and symbolic matrices as Julia functions
using RewriteCAS
RewriteCAS.restart()

println(rw"""
SYM a, b, n : real
"---- a list is a vector: arithmetic element by element"
[1,2,3] + [10,20,30]
x*[1,2] + [a,b]
range(5)^2

"---- a list of rows is a matrix: products are matrix products"
[[1,2],[3,4]] * [[0,1],[1,0]]
[[1,2],[3,4]] * [5,6]
[[2,1],[1,2]]^3

"---- with symbolic entries"
SYM g : real
det([[a,b],[g,n]])
inverse([[a,b],[g,n]])
linsolve([[2,1],[1,3]], [3,5])

"---- the characteristic polynomial"
det([[2,1],[1,2]] - x*identity(2))

"---- covectors: transpose(v)*w is a number, v*transpose(w) a matrix"
transpose([1,2,3]) * [4,5,6]
[1,2] * transpose([3,4])

"---- list functions"
part([[1,2],[3,4]], 2, 1)
SYM kk : real
REWR table(x^kk, kk, range(4)) : All
REWR select(range(10), kk, kk > 6) : All
""")

# ---- in Julia: the symbolic inverse as a function, compared with inv
Minv = rw_function("inverse([[a,b],[g,n]])", :a, :b, :g, :n)
M = [2.0 1.0; 0.5 3.0]
println(Minv(M[1, 1], M[1, 2], M[2, 1], M[2, 2]))
println(inv(M))
# the roots of the characteristic polynomial are the eigenvalues (1 and 3)
p = rw_function("det([[2,1],[1,2]] - x*identity(2))", :x)
println("p(1) = $(p(1)), p(3) = $(p(3))")
