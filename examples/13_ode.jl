# 13_ode.jl: ordinary differential equations (examples/13 of rewrite), and a
# Runge-Kutta loop in Julia compared with the exact solution from rewrite
using RewriteCAS
RewriteCAS.restart()

println(rw"""
SYM t : real
SYM c1, c2 : real          # constants of integration
SYM lambda : complex

"---- a solution checked: u'' + 2 u' + 5 u = 0"
TERM u : real
u = exp(-t)*(c1*cos(2*t) + c2*sin(2*t))
REWR D(D(u,t),t) + 2*D(u,t) + 5*u : All

"---- where it comes from: the characteristic equation"
REWR solve(lambda^2 + 2*lambda + 5 == 0, lambda) : Solve

"---- y' + p y = q: y = exp(-P) (Int(q exp(P)) + c1), where P = Int(p)"
TERM pint, ysol : real
"y' + 2 y = x"
pint = REWR Int(2, x) : RubiIntegrate
ysol = REWR exp(-pint)*(Int(x*exp(pint), x) + c1) : RubiIntegrate, All
ysol
REWR D(ysol,x) + 2*ysol - x : All                             # the check

"---- separation of variables: y' = x y^2, so Int(1/y^2, y) = Int(x, x) + c1"
REWR solve(-1/y == x^2/2 + c1, y) : Solve

"---- Picard iteration for y' = y, y(0) = 1"
SYM kk, tau : real
TERM yk : real
yk = 1
FOR kk = 1 TO 4 DO yk = REWR 1 + Int(Sub(yk, x, tau), tau, 0, x) : All
yk                        # the Taylor polynomial of exp(x)
""")

# ---- in Julia: y' + 2y = x with y(0) = 1 by Runge-Kutta, and exactly:
# the solution of rewrite with c1 chosen for y(0) = 1 (c1 = 5/4)
ysol = rw_function("ysol", :x, :c1)
f(x, y) = x - 2y
global y = 1.0
h = 0.01
for k in 0:99
    x = k * h
    k1 = f(x, y); k2 = f(x + h/2, y + h/2*k1); k3 = f(x + h/2, y + h/2*k2); k4 = f(x + h, y + h*k3)
    global y += h/6 * (k1 + 2k2 + 2k3 + k4)
end
println("y(1): Runge-Kutta $y,  exact $(ysol(1.0, 5/4))")
