# 01_basics.jl: numbers, symbols, terms and sorts (examples/01_basics.rw of
# rewrite), and the results in Julia.  julia --project examples/01_basics.jl
using RewriteCAS
RewriteCAS.restart()          # a new session: no definitions of other examples

println(rw"""
"---- a plain expression is calculated"
2^10 + sqrt(16)
sin(pi/2)
1/3 + 1/6

"---- a symbol stands for itself until it gets a value"
SYM r : real
2*pi*r
r = 2
2*pi*r
r = nothing
2*pi*r

"---- a TERM stores a whole expression"
TERM area : real
area = pi*r^2
REWR D(area, r) : All

"---- the sort of a term"
TYPEOF r
TYPEOF 1/2
TYPEOF area
""")

# ---- in Julia: values and functions
println(rw_expr("1/3 + 1/6"))                 # 1//2, an exact Rational
circumference = rw_function("REWR D(area, r) : All", :r)
println(circumference(1.0), " ≈ ", 2pi)
