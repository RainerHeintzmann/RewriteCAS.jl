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
"""
rw_expr(statements::AbstractString) = julia_expr(result_line(rewrite(statements)))

# the free symbols of an expression (not the functions), sorted
free_symbols(x) = Symbol[]
free_symbols(s::Symbol) = isdefined(Base, s) ? Symbol[] : [s]    # pi, im, ℯ, Inf are no variables
function free_symbols(ex::Expr)
    args = ex.head == :call ? ex.args[2:end] : ex.args
    return sort!(unique!(reduce(vcat, map(free_symbols, args); init = Symbol[])))
end

"""
    rw_function(statements, vars...) -> Function

Runs the statements and returns their result as a Julia function of the
variables `vars` (symbols; by default all free symbols, sorted):

    f = rw_function("REWR Int(x*exp(x),x) : RubiIntegrate", :x)
    f(1.0)                                   # 0.0
    g = rw_function("REWR D(a*x^3,x) : All", :x, :a)
    g(2.0, 0.5)                              # 6.0

The function is built with `eval` in `Main`, so functions that rewrite knows
and Julia has in another package (`erf` of SpecialFunctions) work once that
package is loaded there. It can be called at once, also inside the function
that created it (through `Base.invokelatest`, which costs a little time per
call); `eval(Expr(:->, :x, rw_expr(...)))` gives the plain function.
"""
function rw_function(statements::AbstractString, vars::Symbol...)
    ex = rw_expr(statements)
    vs = isempty(vars) ? free_symbols(ex) : collect(vars)
    f = Core.eval(Main, Expr(:->, Expr(:tuple, vs...), ex))
    return (args...) -> Base.invokelatest(f, args...)
end
