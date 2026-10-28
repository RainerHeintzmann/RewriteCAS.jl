# 15_series.jl: Taylor polynomials Tay(f, x, a, n) (examples/15 of rewrite),
# and their error, computed in Julia
using RewriteCAS
RewriteCAS.restart()

println(rw"""
"---- around 0"
REWR Tay(cos(x), x, 0, 8) : All
REWR Tay(exp(x), x, 0, 5) : All
REWR Tay(ln(1+x), x, 0, 5) : All
REWR Tay(tan(x), x, 0, 7) : All
REWR Tay(sqrt(1+x), x, 0, 3) : All      # the binomial series
REWR Tay(exp(-x^2), x, 0, 6) : All

"---- around another point, and a product"
REWR Tay(sin(x), x, pi/2, 4) : All
REWR Tay(exp(x)*sin(x), x, 0, 5) : All

"---- a Taylor polynomial is a polynomial: its derivative is again one"
REWR D(Tay(sin(x), x, 0, 7), x) : All
""")

# ---- in Julia: the error of the Taylor polynomials of cos at x = 1 for
# growing order; it falls like 1/(n+1)!
for n in 2:2:10
    p = rw_function("REWR Tay(cos(x), x, 0, $n) : All", :x)
    println("order $n:  error $(abs(p(1.0) - cos(1.0)))")
end
