# The example scripts of the package (folder examples): an overview, the
# source of one, or running it.

const EXAMPLES = normpath(joinpath(@__DIR__, "..", "examples"))

example_files() = sort(filter(endswith(".jl"), readdir(EXAMPLES)))

# the description of an example: its row in the table of examples/README.md,
# | [13_ode.jl](13_ode.jl) | in rewrite | in Julia |
function example_title(file)
    for line in eachline(joinpath(EXAMPLES, "README.md"))
        cols = strip.(split(line, '|'))
        length(cols) >= 5 && occursin("[$file]", cols[2]) && return replace("$(cols[3]); Julia: $(cols[4])", "`" => "")
    end
    return ""
end

# the file of an example: by its number (13) or a part of its name ("ode")
function example_file(which)
    files = example_files()
    key = which isa Integer ? lpad(which, 2, '0') * "_" : lowercase(string(which))
    hits = filter(f -> which isa Integer ? startswith(f, key) : occursin(key, lowercase(f)), files)
    exact = filter(f -> lowercase(f[4:end-3]) == key, hits)	# "ode" is 13_ode, not 09_unicode
    length(exact) == 1 && return exact[1]
    length(hits) == 1 && return hits[1]
    error("RewriteCAS: " * (isempty(hits) ? "no example " : "several examples match ") *
          repr(which) * "; rewrite_examples() lists them")
end

"""
    rewrite_examples()
    rewrite_examples(which; run = false)

Without an argument: the list of the examples (the examples of rewrite, each
followed by a part in Julia). With `which`, a number or a part of the name
(`rewrite_examples(13)`, `rewrite_examples("ode")`): the source of that
example; with `run = true` it is also run, in a new rewrite session.

See also [`rw_function`](@ref), which most examples use to turn a result
into a Julia function.
"""
function rewrite_examples()
    println("Examples of RewriteCAS (", EXAMPLES, "):\n")
    for f in example_files()
        println("  ", rpad(splitext(f)[1], 22), example_title(f))
    end
    println("\nrewrite_examples(13) or rewrite_examples(\"ode\") shows one, with run = true it runs it")
    return nothing
end

function rewrite_examples(which; run::Bool = false)
    file = joinpath(EXAMPLES, example_file(which))
    print(read(file, String))
    if run
        println("\n", "-"^20, " output ", "-"^20)
        m = Module(:RewriteExample)
        Core.eval(m, :(eval(x) = Core.eval($m, x)))
        Base.include(m, file)
    end
    return nothing
end
