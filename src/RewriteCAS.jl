"""
    RewriteCAS

Julia access to [rewrite](https://github.com/RainerHeintzmann/rewrite), a
computer algebra system based on term rewriting. One rewrite process runs
in the background with its standard library (`INC "inc/all"`) loaded; the
statements are passed to it as text, and its output comes back as text.

- `rewrite("REWR D(sin(x)^2,x) : All")` returns the output as a `String`.
- `rw"REWR D(sin(x)^2,x) : All"` shows it (as `Text`).
- In the REPL, `}` switches to the `rewrite>` mode; backspace returns.
- `RewriteCAS.restart()` starts a new session.

The program is taken from `ENV["REWRITE_EXE"]` if set, otherwise from the
artifact of this package, otherwise from `rewrite` in the `PATH`.
"""
module RewriteCAS

using Artifacts, Pkg, REPL, ReplMaker

export rewrite, @rw_str, rw_expr, rw_function, rewrite_examples

const MARKER = "@@END@@"	# printed after each input, so that the answer is known to be complete

mutable struct Session
    proc::Base.Process
    input::Pipe
    output::Pipe
end

const SESSION = Ref{Union{Nothing,Session}}(nothing)

# the rewrite program of the artifact (Artifacts.toml), or nothing
function artifact_executable()
    toml = joinpath(@__DIR__, "..", "Artifacts.toml")
    isfile(toml) || return nothing
    meta = Artifacts.artifact_meta("rewrite", toml)		# for this platform
    meta === nothing && return nothing
    dir = Pkg.Artifacts.ensure_artifact_installed("rewrite", meta, toml)
    tops = readdir(dir)		# the tarball has one folder rewrite-VERSION-SYSTEM-MACHINE
    root = length(tops) == 1 ? joinpath(dir, tops[1]) : dir
    return joinpath(root, "bin", Sys.iswindows() ? "rewrite.exe" : "rewrite")
end

"""
    RewriteCAS.executable()

The path of the rewrite program: `ENV["REWRITE_EXE"]`, the artifact of the
package, or `rewrite` in the `PATH`.
"""
function executable()
    exe = get(ENV, "REWRITE_EXE", "")
    isempty(exe) || return exe
    exe = artifact_executable()
    exe === nothing || return exe
    exe = Sys.which("rewrite")
    exe === nothing || return exe
    error("RewriteCAS: no rewrite program found; set ENV[\"REWRITE_EXE\"] to its path")
end

function start()
    input, output = Pipe(), Pipe()
    proc = run(pipeline(`$(executable())`; stdin=input, stdout=output, stderr=output); wait=false)
    close(input.out)
    close(output.in)
    s = Session(proc, input, output)
    SESSION[] = s
    send(s, "INC \"inc/all\"")
    return s
end

# the session, started on first use (or again if rewrite has ended)
session() = (s = SESSION[]; s !== nothing && process_running(s.proc) ? s : start())

# writes the statements and reads the output up to the marker
function send(s::Session, statements::AbstractString)
    write(s.input, statements, "\n\"", MARKER, "\"\n")
    flush(s.input)
    lines = String[]
    while true
        eof(s.output) && error("RewriteCAS: rewrite has ended:\n" * join(lines, "\n"))
        line = rstrip(readline(s.output))
        line == MARKER && break
        push!(lines, line)
    end
    return join(lines, "\n")
end

"""
    rewrite(statements; pretty = false) -> String

Runs rewrite statements (one or more lines) in the session and returns their
output, e.g. `rewrite("REWR D(sin(x)^2,x) : All")` gives `"2 * cos (x )* sin (x )"`.
With `pretty = true` the output uses Unicode (rewrite's `PRETTY 1`):
`"2·cos(x)·sin(x)"`, `x²`, `√x`, `π`.
"""
function rewrite(statements::AbstractString; pretty::Bool = false)
    pretty || return send(session(), statements)
    return send(session(), "PRETTY 1\n" * statements * "\nPRETTY 0")
end

"""
    rw"statements"

Runs the statements like `rewrite` and shows the output as text, with Unicode
(`x²`, `√x`, `π`).
"""
macro rw_str(statements)
    :(Text(rewrite($statements; pretty = true)))
end

include("convert.jl")
include("examples.jl")

"""
    RewriteCAS.restart()

Ends the rewrite session; the next call starts a new one (definitions are lost).
"""
function restart()
    s = SESSION[]
    if s !== nothing
        close(s.input)
        wait(s.proc)
        SESSION[] = nothing
    end
    return nothing
end

# the REPL mode: } switches to rewrite>; \alpha TAB gives α as in Julia
function repl_line(line::AbstractString)
    out = rewrite(line; pretty = true)
    isempty(out) || println(out)
    return nothing
end

# Enter continues the input in an open block { ... } or after a \ at the end
function complete_input(s)
    text = String(take!(copy(REPL.LineEdit.buffer(s))))
    return count(==('{'), text) <= count(==('}'), text) && ! endswith(rstrip(text), "\\")
end

"""
    RewriteCAS.repl_mode(; start_key = '}')

Adds the `rewrite>` mode to the Julia REPL (done when the package is loaded
in an interactive session).
"""
repl_mode(; start_key = '}') =
    initrepl(repl_line; prompt_text = "rewrite> ", prompt_color = :green,
             start_key = start_key, mode_name = "rewrite", startup_text = false,
             valid_input_checker = complete_input)

function __init__()
    if isdefined(Base, :active_repl) && isinteractive()
        repl_mode()
    end
end

end # module
