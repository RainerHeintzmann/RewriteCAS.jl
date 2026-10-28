# Examples

The examples of [rewrite](https://github.com/RainerHeintzmann/rewrite/tree/main/examples),
here from Julia: each script runs the statements of the rewrite example in
a new session (`rw"""..."""`, printed with Unicode) and then uses some of the
results in Julia, as numbers or as functions (`rw_expr`, `rw_function`),
for example to check them with a difference quotient or a sum.

```text
julia --project examples/02_differentiation.jl
```

or, in the REPL, `include("examples/02_differentiation.jl")`.

| File | rewrite | in Julia |
| --- | --- | --- |
| [01_basics.jl](01_basics.jl) | numbers, symbols, terms, sorts | an exact `Rational`, the derivative of a `TERM` as a function |
| [02_differentiation.jl](02_differentiation.jl) | `D` (partial), `Dt` (total) | the derivative compared with a difference quotient |
| [03_integration.jl](03_integration.jl) | `Integrate`, `RubiIntegrate`, a check with `cancel` | a definite integral from the antiderivative, compared with the midpoint rule |
| [04_exact.jl](04_exact.jl) | fractions, big integers, exact values | `Rational`, `Int128`, `BigInt`, an `Expr` |
| [05_lists_matrices.jl](05_lists_matrices.jl) | lists, matrices, `det`, `inverse`, covectors | the symbolic inverse as a function, compared with `inv` |
| [06_equations.jl](06_equations.jl) | `solve` | complex roots put into the polynomial |
| [07_own_rules.jl](07_own_rules.jl) | rule sets: Fibonacci, logarithm laws, conditions | the same Fibonacci number in Julia |
| [08_numerics.jl](08_numerics.jl) | numerical integral, Newton, minimum, loops | Newton's method in Julia with the derivative from rewrite |
| [09_unicode.jl](09_unicode.jl) | Unicode names, `x²`, `√` | the same names as Julia variables; plain and pretty output |
| [10_limits.jl](10_limits.jl) | limits, definite integrals, `heaviside`, `dirac` | a parameter integral as a function, compared with a sum |
| [11_laplace.jl](11_laplace.jl) | Laplace transforms, an initial value problem | the solution checked in the differential equation |
| [12_fourier.jl](12_fourier.jl) | Fourier transforms: table, integral, theorems | a complex transform compared with a sum |
| [13_ode.jl](13_ode.jl) | ordinary differential equations | Runge-Kutta in Julia against the exact solution |
| [14_pde.jl](14_pde.jl) | wave, heat, Laplace equation, Fourier in x | the heat kernel: its total stays 1 |
| [15_series.jl](15_series.jl) | Taylor polynomials | the error for growing order |

The tests run them as well (`test/runtests.jl`).
