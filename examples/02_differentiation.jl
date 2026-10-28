# 02_differentiation.jl: D(f,x), the partial derivative, and Dt(f,x), the
# total one (as in Mathematica), with the rule set All (examples/02 of rewrite)
using RewriteCAS
RewriteCAS.restart()

println(rw"""
REWR D(x^3 + 2*x, x) : All
REWR D(sin(x)^2, x) : All
REWR D(x^2*exp(-x), x) : All
REWR D(ln(sin(x)), x) : All
REWR D(arctan(2*x), x) : All

"---- a second derivative"
REWR D(D(x^4*cos(x), x), x) : All

"---- D(f,x) takes every other symbol as a constant (a partial derivative)"
SYM kk : real
REWR D(x^2*y + y^3, y) : All
REWR D(kk*x^2 + sin(kk*x), x) : All

"---- Dt(f,x) does not: y may depend on x (implicit differentiation)"
REWR Dt(x^2 + y^2, x) : All
""")

# ---- in Julia: the derivative as a function, checked by a difference quotient
f(x) = x^2 * exp(-x)
df = rw_function("REWR D(x^2*exp(-x), x) : All", :x)
h = 1e-6
for x in (0.5, 1.0, 2.0)
    println("x = $x:  rewrite $(df(x)),  difference quotient $((f(x + h) - f(x - h)) / 2h)")
end
