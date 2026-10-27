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
        # results as Julia expressions and functions
        @test rw_expr("REWR D(sin(x)^2,x) : All") == :(2 * cos(x) * sin(x))
        @test rw_expr("1/3 + 1/6") == 1//2
        @test rw_expr("2+3*im") == 2 + 3im
        @test eval(rw_expr("[[1, 2], [3, 4]] * [5, 6]")) == [17, 39]
        f = rw_function("REWR Tay(cos(x),x,0,8) : All", :x)
        @test f(0.5) ≈ cos(0.5) atol = 1e-8
        g = rw_function("REWR D(b*x^3,x) : All", :x, :b)
        @test g(2.0, 0.5) ≈ 6.0
        h = rw_function("REWR Int(x*exp(x),x) : RubiIntegrate")	# the variables found: x
        @test h(1.0) ≈ 0.0 atol = 1e-12
        m = rw_function("SYM c : real\ninverse([[c, 1], [1, c]])", :c)
        @test m(2.0) ≈ inv([2.0 1; 1 2])
        @test_throws ErrorException rw_expr("AUTOSYM\nundeclared + 1")
    end
end
