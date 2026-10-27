# RewriteCAS.jl

Julia access to [rewrite](https://github.com/RainerHeintzmann/rewrite), a
computer algebra system based on term rewriting: derivatives, integrals
(the translated Rubi rules), exact numbers, equations, limits, Laplace and
Fourier transforms, lists and matrices, all defined by rules in its library.

```julia
using RewriteCAS

rewrite("REWR D(sin(x)^2,x) : All")              # "2 * cos (x )* sin (x )"
rw"REWR Int(x*exp(x),x) : RubiIntegrate"         # shown as text: x * exp (x )- exp (x )
```

Results can also come back as Julia expressions and functions:

```julia
rw_expr("REWR D(sin(x)^2,x) : All")              # :(2 * cos(x) * sin(x))
f = rw_function("REWR Tay(cos(x),x,0,8) : All")  # a function of x
f(0.5)                                           # 0.87758256..., cos(0.5) = 0.87758256...
g = rw_function("SYM a, t : positive\ninvfourier(exp(-a*w^2*t), w, x)", :x, :a, :t)
g(0.3, 1.0, 2.0)                                 # the heat kernel
```

In the REPL, `}` switches to the `rewrite>` mode (backspace at the start of
the line returns to Julia). It has Julia's line editing, history and
`\alpha` + TAB completion; `?REWR` shows the help of rewrite:

```text
julia> }
rewrite> SYM s : positive
rewrite> SYM t : real
rewrite> invlaplace(1/(s^2+3*s+2), s, t)
exp (- t )- exp (- 2 * t )
```

## How it works

One rewrite process runs in the background, with the standard library
(`INC "inc/all"`) loaded at the first call (about a second). Statements
are passed to it as text and its output comes back as text, so all of the
rewrite language is available, and definitions (`SYM`, `TERM`, rules) are
kept between the calls. `RewriteCAS.restart()` starts a new session.

| Function | |
| --- | --- |
| `rewrite(statements)` | runs one or more lines, returns the output as a `String` |
| `rw"statements"` | the same, shown as `Text` |
| `rw_expr(statements)` | the result (the last one) as a Julia `Expr`: `1//2` for `(1/2)`, `log` for `ln`, `[a, b]`, matrices, `Complex` |
| `rw_function(statements, vars...)` | the result as a Julia function of `vars` (symbols; default: its free symbols, sorted) |
| `RewriteCAS.julia_expr(text)` | the `Expr` of a term printed by rewrite |
| `RewriteCAS.restart()` | ends the session; the next call starts a new one |
| `RewriteCAS.executable()` | the rewrite program in use |
| `RewriteCAS.repl_mode(; start_key = '}')` | adds the REPL mode (done by `using` in the REPL) |

`rw_function` builds the function with `eval` in `Main`: a function that
rewrite knows and Julia only has in a package, such as `erf`, works once that
package is loaded (`using SpecialFunctions`). New names need no declaration
in the session (`AUTOSYM real` of `inc/all`); declare those that have a
sign, e.g. `SYM a : positive`, since some results depend on it.

The language itself is described in the
[rewrite README](https://github.com/RainerHeintzmann/rewrite#readme).

## The rewrite program

The program is taken from

1. `ENV["REWRITE_EXE"]`, if set (for example a program you built yourself),
2. the artifact of this package: the release tarball of rewrite for Linux
   and Windows (x86_64), downloaded at the first use,
3. `rewrite` in the `PATH` (for example after `make install`).

On other systems (macOS), build rewrite from its sources and set
`REWRITE_EXE` or install it.

## A new rewrite release

`Artifacts.toml` names the release tarballs of rewrite: their URLs on the
GitHub release, a SHA-256 checksum of each file, and the hash of the
unpacked folder. Julia downloads the tarball for the platform at the first
use and checks both. For a new version of rewrite (here 2026.1):

1. In rewrite: set `VERSION` in the makefile, commit, and build the
   tarballs from that commit: `make bindist` on Linux and on Windows gives
   `rewrite-2026.1-linux-x86_64.tar.gz` and
   `rewrite-2026.1-windows-x86_64.tar.gz`.
2. Here: `julia release/make_artifacts.jl 2026.1 path/to/rewrite` writes
   `Artifacts.toml` from these two files, with the URLs of step 3.
3. On GitHub, rewrite → Releases → "Draft a new release": tag `v2026.1`
   (created on publishing), attach exactly the two files of step 1, publish.
4. Here: raise `version` in `Project.toml`, commit and push.

The files must not be built again between steps 2 and 3, since the
checksums would no longer fit. To test the download, delete the folder
`~/.julia/artifacts/<git-tree-sha1>` (step 2 has put it there) and call
`RewriteCAS.restart(); rewrite("1+1")` without `REWRITE_EXE`.

## License

MIT, as rewrite.
