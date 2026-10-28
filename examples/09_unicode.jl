# 09_unicode.jl: Unicode names, written directly or as \alpha (examples/09 of
# rewrite); rw"..." prints with Unicode (x², √x, π), as rewrite's PRETTY 1
using RewriteCAS
RewriteCAS.restart()

println(rw"""
SYM α, \beta, \theta : real
REWR D(sin(α*θ) + \beta^2, θ) : All
REWR Int(exp(-α*x), x) : RubiIntegrate
SYM x\_1, x\_2 : real
x₁ + x₂
TYPEOF x₁
"---- superscripts are powers, √ is sqrt"
REWR D(x² + √(1 + x), x) : All
""")

# ---- in Julia: the same names are Julia variables
g = rw_function("REWR D(sin(α*θ) + β^2, θ) : All", :α, :θ)
println(g(2.0, 0.1), " = ", 2cos(0.2))
println(rewrite("REWR Tay(cos(x),x,0,6) : All"))                  # with Unicode
println(rewrite("REWR Tay(cos(x),x,0,6) : All"; pretty = false))  # plain text
