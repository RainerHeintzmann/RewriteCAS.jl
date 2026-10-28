# 04_exact.jl: exact numbers (examples/04 of rewrite), and as Julia numbers
using RewriteCAS
RewriteCAS.restart()

println(rw"""
"---- fractions and big integers stay exact"
1/3 + 1/6
2^100
(2/3)^-2
10!

"---- a real number makes it numerical"
1/3 + 0.5

"---- in REWR, functions of exact numbers stay terms unless their value is exact"
REWR sqrt(8) : All
REWR sin(pi/6) + cos(pi/3) : All
REWR ln(8)/ln(2) : All
REWR arcsin(1/2) : All
""")

# ---- in Julia: exact results become Rational, Int128 or BigInt, terms an Expr
println(rw_expr("(2/3)^-2"), "  ", typeof(rw_expr("(2/3)^-2")))
println(rw_expr("2^100"), "  ", typeof(rw_expr("2^100")))      # Int128 (BigInt for larger ones)
ex = rw_expr("REWR sqrt(8) : All")              # :(2 * 2 ^ (1//2))
println(ex, " = ", eval(ex))
