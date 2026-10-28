# 08_numerics.jl: numerical methods of rewrite (examples/08 of rewrite), and
# a symbolic derivative used by Newton's method in Julia
using RewriteCAS
RewriteCAS.restart()

println(rw"""
"---- a definite integral, a zero by Newton's method, a minimum"
REWR I(0, 1, x^2, x) : numerik,calc
REWR newton(1, x^2 - 2, D(x^2 - 2, x), x) : numerik,calc
REWR fmin(-1, 1, (x - 0.3)^2, x) : numerik,calc

"---- printing with more digits"
PRTNUM "%.12g "
sqrt(2)
PRTNUM "%g "

"---- a loop"
SYM n : real
FOR n = 1 TO 5 DO n^2
""")

# ---- in Julia: f and its derivative from rewrite, Newton's method in Julia
f  = rw_function("x^3 - 2*x - 5", :x)
df = rw_function("REWR D(x^3 - 2*x - 5, x) : All", :x)
global z = 2.0
for _ in 1:6
    global z -= f(z) / df(z)
end
println("the zero of x^3 - 2x - 5: $z,  f(z) = $(f(z))")
