module LSH

using Distributions, LinearAlgebra, SparseArrays

include("utils.jl")
include("LSHBase.jl")

# Hash functions
include(joinpath("hashes", "simhash.jl"))
include(joinpath("hashes", "lphash.jl"))
include(joinpath("hashes", "mips_hash.jl"))
include(joinpath("hashes", "sign_alsh.jl"))

export SimHash, LpHash, L1Hash, L2Hash, MIPSHash,
	SignALSH, hashtype, index_hash, query_hash, n_hashes,
	redraw!

end # module
