# 06_equations.jl: solving equations with the rule set Solve (examples/06 of
# rewrite); the solutions as Julia numbers, checked in Julia
using RewriteCAS
RewriteCAS.restart()

println(rw"""
"---- polynomials"
REWR solve(x^2 - 3*x + 2 == 0, x) : Solve
REWR solve(x^2 + 4*x + 7 == 0, x) : Solve
REWR solve(x^3 - 6*x^2 + 11*x - 6 == 0, x) : Solve

"---- isolation and a new unknown"
REWR solve(exp(2*x+1) == 5, x) : Solve
REWR solve(sin(x) == 1/2, x) : Solve
REWR solve(exp(2*x) - 3*exp(x) + 2 == 0, x) : Solve
REWR solve(sqrt(x+1) == x - 1, x) : Solve

"---- systems"
REWR solve([x + y == 3, x - y == 1], [x, y]) : Solve
REWR solve([x^2 + y^2 == 5, x - y == 1], [x, y]) : Solve
""")

# ---- in Julia: the complex roots as numbers, put into the polynomial
roots = eval(rw_expr("REWR solve(x^2 + 4*x + 7 == 0, x) : Solve"))
for r in roots
    println("x = $r:  x^2 + 4x + 7 = $(r^2 + 4r + 7)")
end
