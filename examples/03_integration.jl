# 03_integration.jl: indefinite integrals (examples/03 of rewrite). Integrate
# is a small rule set, RubiIntegrate the translated Rubi rules.
using RewriteCAS
RewriteCAS.restart()

println(rw"""
"---- with Integrate"
REWR Int(x^2, x) : Integrate
REWR Int(x*sin(x), x) : Integrate
REWR Int(1/(2*x+3), x) : Integrate
REWR Int(x*exp(2*x), x) : Integrate

"---- with RubiIntegrate"
REWR Int(1/(1+x^2), x) : RubiIntegrate
REWR Int(sin(x)^2, x) : RubiIntegrate
REWR Int(x/(1+x^4), x) : RubiIntegrate
REWR Int(sqrt(x)/(1+x), x) : RubiIntegrate
REWR Int(ln(x)^2, x) : RubiIntegrate

"---- check: the derivative of the result is the integrand"
"---- (cancel puts it over a common denominator and simplifies)"
TERM Fx : number
Fx = REWR Int(1/(1+x^4), x) : RubiIntegrate
Fx
REWR cancel(D(Fx, x)) : All
""")

# ---- in Julia: the antiderivative as a function; a definite integral from it,
# compared with a sum (the midpoint rule)
F = rw_function("REWR Int(1/(1+x^5), x) : RubiIntegrate", :x)
f(x) = 1 / (1 + x^5)
n = 100_000
midpoint = sum(f((k - 0.5) / n) for k in 1:n) / n
println("Int(1/(1+x^5), x, 0, 1):  F(1) - F(0) = $(F(1.0) - F(0.0)),  midpoint rule $midpoint")
