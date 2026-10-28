# 07_own_rules.jl: your own rule sets (examples/07 of rewrite). A rule set
# (ALG) is a list of rules left = right; PAT declares the pattern variables,
# NUMPAT those that only match numbers.
using RewriteCAS
RewriteCAS.restart()

println(rw"""
SYM a, b : real
FUNC fib : real >> real
NUMPAT Nf : real
ALG Fib
SPEC    Fib : fib(0) = 0
ADDSPEC Fib : fib(1) = 1
ADDSPEC Fib : IF (Nf > 1) fib(Nf) = fib(Nf - 1) + fib(Nf - 2)
"---- fib(15) by the rules"
REWR fib(15) : (Fib, All)

"---- rules with symbols: the logarithm laws"
PAT Lu, Lv : real
ALG Logs
SPEC    Logs : ln(Lu*Lv) = ln(Lu) + ln(Lv)
ADDSPEC Logs : ln(Lu^Lv) = Lv*ln(Lu)
REWR ln(a*b^3) : (Logs)

"---- conditions: a linear map lin takes out factors free of x (NIN)"
FUNC lin : real >> real
PAT Lc : real
ALG Lin
SPEC    Lin : lin(Lu + Lv) = lin(Lu) + lin(Lv)
ADDSPEC Lin : IF NIN(x, Lc) lin(Lc*Lu) = Lc*lin(Lu)
REWR lin(3*x^2 + y*sin(x) + 5) : (Lin)
""")

# ---- in Julia: the same Fibonacci number
fib(n) = n < 2 ? n : fib(n - 1) + fib(n - 2)
println("rewrite: ", rw_expr("REWR fib(15) : (Fib, All)"), ",  Julia: ", fib(15))
