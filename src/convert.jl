# Results of rewrite as Julia expressions and functions. The printed form of
# rewrite is almost Julia syntax: "2 * cos (x )* sin (x )". Differences: a
# space before the parentheses of a call, some names (ln, arctan, mi(u) =
# 1/u), and (1/2) is an exact fraction (here 1//2).

# names of rewrite -> Julia (functions of Base or of this module)
const FUNCTIONS = Dict(
    :ln => :log, :lg => :log10, :arcsin => :asin, :arccos => :acos,
    :arctan => :atan, :arccot => :acot, :arcsec => :asec, :arccsc => :acsc,
    :arcsinh => :asinh, :arccosh => :acosh, :arctanh => :atanh,
    :mi => :inv, :heaviside => :(RewriteCAS.heaviside), :Gamma => :gamma)
const CONSTANTS = Dict(:infinity => :Inf, :e => :ℯ)

"""
    RewriteCAS.heaviside(x)

The step function of rewrite: 0 for x < 0, 1/2 at 0, 1 for x > 0.
"""
heaviside(x::Real) = x > 0 ? one(x) : x < 0 ? zero(x) : one(x) / 2

# the last result of the output, as one line: a list continues on lines that
# begin with a blank ("[1,\n 2]"), a matrix is printed as rows "[ a  b ]"
# (columns two blanks apart), which become hvcat((2,2), a, b, c, d)
function result_line(out::AbstractString)
    any(l -> startswith(l, "Error"), split(out, '\n')) &&
        error("RewriteCAS: rewrite reported an error:\n" * out)
    groups = String[]
    for l in split(rstrip(out), '\n')
        isempty(strip(l)) && continue
        if startswith(l, ' ') && !isempty(groups)
            groups[end] *= " " * strip(l)
        else
            push!(groups, strip(l))
        end
    end
    isempty(groups) && error("RewriteCAS: no result")
    rows = String[]                  # a matrix: the last lines "[ ... ]" without commas
    while !isempty(groups) && occursin(r"^\[ .* \]$", groups[end]) && !occursin(',', groups[end])
        pushfirst!(rows, pop!(groups))
    end
    isempty(rows) && return groups[end]
    entries = [split(strip(r[2:end-1]), r"\s{2,}") for r in rows]
    return "hvcat((" * join(length.(entries), ",") * ",), " * join(reduce(vcat, entries), ", ") * ")"
end

convert_names(x) = x
convert_names(s::Symbol) = get(CONSTANTS, s, s)
function convert_names(ex::Expr)
    m = ex.head == :macrocall ? ex.args[1] : nothing
    m isa GlobalRef && (m = m.name)
    if m in (Symbol("@int128_str"), Symbol("@uint128_str"), Symbol("@big_str"))
        return Core.eval(@__MODULE__, ex)      # 2^100: Julia parses big literals as a macro call
    end
    args = map(convert_names, ex.args)
    if ex.head == :call
        f = ex.args[1]
        args[1] = get(FUNCTIONS, f, f)
        if f == :/ && length(args) == 3 && all(a -> a isa Integer, args[2:3])
            return args[2] // args[3]          # (1/2): an exact fraction
        end
    end
    return Expr(ex.head, args...)
end

"""
    julia_expr(text) -> Expr

The Julia expression of a term printed by rewrite, for example
`julia_expr("2 * cos (x )* sin (x )")` gives `:(2 * cos(x) * sin(x))`.
"""
function julia_expr(text::AbstractString)
    s = replace(text, r"([\w\)\]])\s+\(" => s"\1(")   # cos (x ) -> cos(x ); no juxtaposition in rewrite
    return complex_values(convert_names(Meta.parse(s)))
end

# a complex value is printed as (2,3): the result itself or the elements of a list
complex_values(x) = x
function complex_values(ex::Expr)
    ex.head == :tuple && length(ex.args) == 2 && all(a -> a isa Real, ex.args) && return Complex(ex.args...)
    ex.head == :vect && return Expr(:vect, map(complex_values, ex.args)...)
    return ex
end

"""
    rw_expr(statements) -> Expr

Runs the statements (as `rewrite`) and returns the result, the last line of
the output, as a Julia expression:

    rw_expr("REWR D(sin(x)^2,x) : All")      # :(2 * cos(x) * sin(x))

See also [`rw_function`](@ref), which makes a Julia function of it.
"""
rw_expr(statements::AbstractString) = julia_expr(result_line(rewrite(statements; pretty = false)))

# the free symbols of an expression (not the functions), sorted
free_symbols(x) = Symbol[]
free_symbols(s::Symbol) = isdefined(Base, s) ? Symbol[] : [s]    # pi, im, ℯ, Inf are no variables
function free_symbols(ex::Expr)
    args = ex.head == :call ? ex.args[2:end] : ex.args
    return sort!(unique!(reduce(vcat, map(free_symbols, args); init = Symbol[])))
end

"""
    RwFunction

A function made from a result of rewrite by `rw_function`, `rw_integral` or
`rw_derivative`. It is called like any function, `f(0.5)`; `?f` shows its
term, and the fields are `vars` (the arguments), `term` (the result as
printed by rewrite, with Unicode), `expr` (the Julia expression) and
`statements` (what rewrite was given).
"""
struct RwFunction{F} <: Function
    f::F
    vars::Vector{Symbol}
    term::String
    expr::Any
    statements::String
end

(r::RwFunction)(args...) = Base.invokelatest(r.f, args...)

# a term of several lines (a matrix) begins on a new line
spaced(term) = occursin('\n', term) ? "\n" * term : " " * term

function Base.show(io::IO, r::RwFunction)
    print(io, "(", join(r.vars, ", "), ") ->", spaced(r.term))
end
Base.show(io::IO, ::MIME"text/plain", r::RwFunction) = show(io, r)

# the help of the function (?f): its term
function Base.Docs.getdoc(r::RwFunction)
    args = join(r.vars, ", ")
    term = replace(spaced(r.term), '\n' => "\n        ")
    return Markdown.parse("""
        f($args)

    A function from rewrite:

        f($args) =$term

    the result of the statements

        $(replace(r.statements, '\n' => "\n    "))

    In Julia: `$(r.expr)`. See [`RwFunction`](@ref).
    """)
end

"""
    rw_function(statements, vars...) -> RwFunction

Runs the statements and returns their result as a Julia function of the
variables `vars` (symbols; by default all free symbols, sorted):

    f = rw_function("REWR Int(x*exp(x),x) : RubiIntegrate", :x)
    f(1.0)                                   # 0.0
    g = rw_function("REWR D(a*x^3,x) : All", :x, :a)
    g(2.0, 0.5)                              # 6.0
    ?g                                       # g(x, a) = 3·a·x²

The function shows its term, as rewrite prints it, and `?g` shows its help.
It is built with `eval` in `Main`, so functions that rewrite knows and Julia
has in another package (`erf` of SpecialFunctions) work once that package is
loaded there. It can be called at once, also inside the function that
created it (through `Base.invokelatest`, which costs a little time per
call); `eval(Expr(:->, :x, rw_expr(...)))` gives the plain function.

See also [`rw_integral`](@ref), [`rw_derivative`](@ref), [`rw_expr`](@ref).
"""
rw_function(statements::AbstractString, vars::Symbol...) = make_function(statements, collect(vars))

# the function of vars; without vars of the free symbols, those of lead first
function make_function(statements, vars, lead = Symbol[])
    ex = rw_expr(statements)
    term = rewrite("%")         # the result again, printed with Unicode
    vs = isempty(vars) ? unique!([lead; free_symbols(ex)]) : vars
    f = Core.eval(Main, Expr(:->, Expr(:tuple, vs...), ex))
    return RwFunction(f, vs, term, ex, statements)
end

"""
    rw_integral(integrand, x, vars...; rules = "RubiIntegrate") -> RwFunction

The antiderivative of `integrand` (a `String` or an `Expr`) with respect to
`x`, as a function of `x` and the other free symbols (sorted), or of `vars`:
runs `REWR Int(integrand,x) : rules`.

    F = rw_integral("x*exp(x)", :x)          # (x) -> x·exp(x) - exp(x)
    F(1.0) - F(0.0)                          # 1.0
    G = rw_integral("exp(-a*x)", :x)         # (x, a) -> -exp(-a·x)/a

See also [`rw_derivative`](@ref), [`rw_function`](@ref).
"""
rw_integral(integrand, x, vars::Symbol...; rules = "RubiIntegrate") =
    make_function("REWR Int($integrand,$x) : $rules", collect(vars), [Symbol(x)])

"""
    rw_derivative(term, x, vars...; rules = "All") -> RwFunction

The partial derivative of `term` (a `String` or an `Expr`) with respect to
`x`, as a function of `x` and the other free symbols (sorted), or of `vars`:
runs `REWR D(term,x) : rules`.

    f = rw_derivative("sin(x)^2", :x)        # (x) -> 2·cos(x)·sin(x)
    g = rw_derivative(:(b*x^3), :x)          # (x, b) -> 3·b·x²

See also [`rw_integral`](@ref), [`rw_function`](@ref).
"""
rw_derivative(term, x, vars::Symbol...; rules = "All") =
    make_function("REWR D($term,$x) : $rules", collect(vars), [Symbol(x)])
