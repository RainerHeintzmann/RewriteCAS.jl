# 11_laplace.jl: the Laplace transform and its inverse, and linear
# differential equations with initial values (examples/11 of rewrite)
using RewriteCAS
RewriteCAS.restart()

println(rw"""
SYM t, w : real
SYM s : positive          # s > 0: the transform as an integral converges
SYM a : positive

"---- transforms"
laplace(t^3, t, s)
laplace(exp(-a*t)*sin(w*t), t, s)
laplace(heaviside(t-2), t, s)
cancel(laplace(t^2*sin(t), t, s))
laplace(erf(t), t, s)                    # not known: stays as it is

"---- inverse transforms (partial fractions, damped oscillations, delays)"
invlaplace(1/(s^2+3*s+2), s, t)
invlaplace(s/(s^2+2*s+5), s, t)
invlaplace(exp(-s)/(s+1), s, t)

"---- u'' + u = 0 with u(0) = 1, u'(0) = 0"
FUNC u : real >> real     # the unknown function
SYM U : real              # its transform
ALG Init
SPEC    Init : u(0) = 1
ADDSPEC Init : initial(Dt(u(t),t),t) = 0     # u'(0); the derivative of u(t) is Dt(u(t),t)
ADDSPEC Init : laplace(u(t),t,s) = U
TERM E : real
TERM R : vector
E = REWR laplace(D(D(u(t),t),t) + u(t), t, s) : Init, All
E
R = REWR solve(E == 0, U) : Solve
invlaplace(part(R,1), s, t)
""")

# ---- in Julia: u'' + 3u' + 2u = 0, u(0) = 0, u'(0) = 1 solved by rewrite,
# the solution checked by differences
u = rw_function("invlaplace(1/(s^2+3*s+2), s, t)", :t)
h = 1e-4
for t in (0.5, 1.0, 2.0)
    d1 = (u(t + h) - u(t - h)) / 2h
    d2 = (u(t + h) - 2u(t) + u(t - h)) / h^2
    println("t = $t:  u'' + 3u' + 2u = $(d2 + 3d1 + 2u(t))")
end
println("u(0) = $(u(0.0)), u'(0) = $((u(h) - u(-h)) / 2h)")
