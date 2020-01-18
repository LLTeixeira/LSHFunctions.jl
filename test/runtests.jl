#================================================================

Testrunner for the LSH module

================================================================#

#==============
Helper functions and constants for LSH
==============#

include("utils.jl")

#========================
Tests
========================#

include("doctests.jl")

include("test_intervals.jl")
include("test_similarities.jl")

include(joinpath("hashes", "test_simhash.jl"))
include(joinpath("hashes", "test_minhash.jl"))
include(joinpath("hashes", "test_lphash.jl"))
include(joinpath("hashes", "test_mips_hash.jl"))
include(joinpath("hashes", "test_sign_alsh.jl"))
include(joinpath("hashes", "test_lshfunction.jl"))

include(joinpath("function_hashing", "test_monte_carlo.jl"))
include(joinpath("function_hashing", "test_chebhash.jl"))
