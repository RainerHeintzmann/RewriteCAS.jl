using RewriteCAS, Test

# needs a rewrite program: ENV["REWRITE_EXE"], the artifact, or rewrite in the PATH
has_rewrite = try
    RewriteCAS.executable()
    true
catch
    false
end

@testset "RewriteCAS" begin
    if ! has_rewrite
        @warn "no rewrite program found, tests skipped (set ENV[\"REWRITE_EXE\"])"
    else
        @test rewrite("REWR D(sin(x)^2,x) : All") == "2 * cos (x )* sin (x )"
        @test rewrite("1/3 + 1/6") == "(1/2)"
        # a session: definitions are kept between the calls
        rewrite("SYM a : real")
        rewrite("a = 3")
        @test rewrite("a + 1") == "4"
        # several statements at once, and an error message
        @test rewrite("1+1\n2+2") == "2\n4"
        @test occursin("syntax error", rewrite("1+"))
        @test rw"2*3" == Text("6")
        RewriteCAS.restart()
        @test occursin("a + 1", rewrite("SYM a : real\na + 1"))	# a new session: a has no value
    end
end
