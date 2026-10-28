# 12_fourier.jl: the Fourier transform F(w) = Int(f(t) exp(-im w t), t) and its
# inverse (examples/12 of rewrite); a transform compared with a sum in Julia
using RewriteCAS
RewriteCAS.restart()

println(rw"""
SYM t, w, b : real
SYM a, T : positive

"---- pairs from the table"
fourier(dirac(t-2), t, w)               # a delay is a phase
fourier(cos(b*t), t, w)                 # a cosine: two deltas
fourier(exp(-a*abs(t)), t, w)           # a Lorentzian
fourier(sin(a*t)/t, t, w)               # sinc: a rectangle

"---- pairs from the integral (inc/limits)"
fourier(exp(-a*t^2), t, w)              # a Gaussian stays a Gaussian
fourier(heaviside(t)*exp(-a*t), t, w)   # a one-sided exponential
fourier(heaviside(t+T)-heaviside(t-T), t, w)    # a rectangle: 2 sin(T w)/w

"---- the theorems"
fourier(t*exp(-t^2), t, w)              # multiplication by t: im*Dt(F,w)
fourier(cos(3*t)*exp(-t^2), t, w)       # modulation shifts the spectrum

"---- the inverse, and back again"
REWR invfourier(2*a/(a^2+w^2), w, t) : All
REWR invfourier(fourier(heaviside(t)*exp(-a*t), t, w), w, t) : All
""")

# ---- in Julia: the transform of the one-sided exponential (complex valued),
# compared with a sum over t
F = rw_function("fourier(heaviside(t)*exp(-a*t), t, w)", :a, :w)
a, w, dt = 0.5, 1.5, 1e-4
println("rewrite: $(F(a, w)),  sum: $(sum(exp(-a*t)*exp(-im*w*t) for t in dt/2:dt:80) * dt)")
