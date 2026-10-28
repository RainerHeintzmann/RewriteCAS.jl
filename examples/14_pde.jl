# 14_pde.jl: partial differential equations (examples/14 of rewrite); the heat
# kernel from rewrite as a Julia function
using RewriteCAS
RewriteCAS.restart()

println(rw"""
SYM k, w : real
SYM a, c, t : positive    # diffusivity, speed, time
TERM u, lap : real

"---- the wave equation u_tt = c^2 u_xx: any f(x - c t) + g(x + c t)"
u = sin(x - c*t) + ln(x + c*t)
REWR D(D(u,t),t) - c^2*D(D(u,x),x) : All

"---- the heat equation u_t = a u_xx: a decaying mode and the heat kernel"
u = exp(-a*k^2*t)*sin(k*x)
REWR D(u,t) - a*D(D(u,x),x) : All
u = exp(-x^2/(4*a*t))*t^(-1/2)
REWR D(u,t) - a*D(D(u,x),x) : All

"---- the Laplace equation u_xx + u_yy = 0: harmonic functions"
u = x^3 - 3*x*y^2
REWR D(D(u,x),x) + D(D(u,y),y) : All
u = ln(x^2 + y^2)
lap = REWR D(D(u,x),x) + D(D(u,y),y) : All
REWR cancel(lap) : All    # over a common denominator: 0

"---- the heat equation on the line, with the Fourier transform in x"
FUNC v : real,real >> real
REWR fourier(D(D(v(x,t),x),x), x, w) : All       # u_xx becomes -w^2 U
invfourier(exp(-a*w^2*t), w, x)                  # the heat kernel
"---- the transport equation u_t + c u_x = 0: the profile moves"
invfourier(pi^(1/2)*exp(-w^2/4)*exp(-im*c*t*w), w, x)
""")

# ---- in Julia: the heat kernel keeps the total heat 1 and spreads over time
G = rw_function("invfourier(exp(-a*w^2*t), w, x)", :x, :a, :t)
dx = 0.01
for t in (0.1, 1.0, 10.0)
    total = sum(G(x, 1.0, t) for x in -60:dx:60) * dx
    println("t = $t:  total $total,  at x = 0: $(G(0.0, 1.0, t))")
end
