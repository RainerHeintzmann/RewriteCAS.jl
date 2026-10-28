# 10_limits.jl: limits at infinity, definite integrals, the step and the delta
# (examples/10 of rewrite); a parameter integral as a Julia function
using RewriteCAS
RewriteCAS.restart()

println(rw"""
SYM t, w : real
SYM a : positive        # a > 0 is known: exp(-a*t) decays

"---- limits for t -> infinity (only finite ones are evaluated)"
limit(t^3*exp(-a*t), t, infinity)
limit(erf(a*t), t, -infinity)
limit((t+1)/(t^2+3), t, infinity)
limit(t*exp(a*t), t, infinity)          # infinite: stays as it is

"---- definite integrals"
Int(t^2, t, 0, 3)
Int(sin(t), t, 0, pi)
Int(t*exp(-a*t), t, 0, infinity)
Int(exp(-a*t^2), t, -infinity, infinity)     # the Gaussian
Int(exp(-a*t)*cos(w*t), t, 0, infinity)
Int(1/t^2, t, -1, 1)                    # 1/t^2 is not continuous at 0: stays

"---- the Heaviside step and the Dirac delta"
heaviside(2), heaviside(-1)
Int(heaviside(t-1)*exp(-a*t), t, -infinity, infinity)
Int(dirac(t-3)*t^2, t, -infinity, infinity)
REWR D(heaviside(t^2-1), t) : All
""")

# ---- in Julia: the Laplace-type integral as a function of a and w,
# compared with a Riemann sum
L = rw_function("Int(exp(-a*t)*cos(w*t), t, 0, infinity)", :a, :w)
a, w, dt = 0.7, 2.0, 1e-4
println("rewrite: $(L(a, w)),  sum: $(sum(exp(-a*t)*cos(w*t) for t in dt/2:dt:60) * dt)")
