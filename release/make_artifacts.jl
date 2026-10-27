# Writes Artifacts.toml for a release of rewrite from the local tarballs
# (make bindist on Linux and Windows): the hashes are computed here, the URLs
# are those of the GitHub release v<version>, where the same files must be
# uploaded unchanged.
#
#   julia release/make_artifacts.jl 2026.1 path/to/rewrite
using Pkg
Pkg.activate(; temp = true)
Pkg.add("SHA"; io = devnull)
using Pkg.Artifacts, SHA, Base.BinaryPlatforms

version, folder = ARGS
toml = joinpath(@__DIR__, "..", "Artifacts.toml")
url = "https://github.com/RainerHeintzmann/rewrite/releases/download/v$version/"

isfile(toml) && rm(toml)
for (sys, platform) in [("linux", Platform("x86_64", "linux")),
                        ("windows", Platform("x86_64", "windows"))]
    file = "rewrite-$version-$sys-x86_64.tar.gz"
    tarball = joinpath(folder, file)
    sha = bytes2hex(open(sha256, tarball))
    tree = create_artifact(dir -> Pkg.PlatformEngines.unpack(tarball, dir))
    bind_artifact!(toml, "rewrite", tree; platform = platform, lazy = true,
                   download_info = [(url * file, sha)], force = true)
    println(file, ": git-tree-sha1 ", bytes2hex(tree.bytes))
end
