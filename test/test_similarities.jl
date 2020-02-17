using Test, Random, LSHFunctions, QuadGK
using LinearAlgebra: dot, norm

include("utils.jl")

#==================
Tests
==================#

@testset "ℓ^p distance and norm tests" begin
    Random.seed!(RANDOM_SEED)

    @testset "Compute ℓ^1 distance and norm" begin
        x = 2.0 * ones(10)
        y = zero(x)

        @test ℓ1_norm(x) == ℓ1(x, zero(x)) == 20
        @test ℓ1_norm(y) == ℓ1(y, zero(y)) == 0

        x = [1, 2, 3, 4]
        y = [1, 2, 0, 0]

        @test ℓ1_norm(x) == 1 + 2 + 3 + 4
        @test ℓ1_norm(y) == 1 + 2
        @test ℓ1(x,y) == ℓ1_norm(x - y) == 3 + 4

        x = randn(128)
        y = randn(128)

        @test ℓ1_norm(x) ≈ x     .|> abs |> sum
        @test ℓ1_norm(y) ≈ y     .|> abs |> sum
        @test ℓ1(x,y)    ≈ x - y .|> abs |> sum

        @test_throws DimensionMismatch ℓ1(zeros(5), zeros(6))
    end

    @testset "Compute ℓ^2 distance and norm" begin
        x = 2.0 * ones(10)
        y = zero(x)

        @test ℓ2_norm(x) == ℓ2(x, zero(x)) == √40
        @test ℓ2_norm(y) == ℓ2(y, zero(y)) == 0

        x = [1, 2, 3, 4]
        y = [1, 2, 0, 0]

        @test ℓ2_norm(x) == √(1^2 + 2^2 + 3^2 + 4^2)
        @test ℓ2_norm(y) == √(1^2 + 2^2)
        @test ℓ2(x,y) == ℓ2_norm(x - y) == √(3^2 + 4^2)

        x = randn(128)
        y = randn(128)

        @test ℓ2_norm(x) ≈ x     .|> abs2 |> sum |> √
        @test ℓ2_norm(y) ≈ y     .|> abs2 |> sum |> √
        @test ℓ2(x,y)    ≈ x - y .|> abs2 |> sum |> √

        @test_throws DimensionMismatch ℓ2(zeros(5), zeros(6))
    end

    @testset "Compute ℓ^p distance and norm" begin
        x = [1, 2, 3, 4]
        y = [1, 2, 0, 0]
        
        @test ℓp_norm(x, 3) ≈ (1^3 + 2^3 + 3^3 + 4^3)^(1/3)
        @test ℓp_norm(y, 3) ≈ (1^3 + 2^3)^(1/3)
        @test ℓp(x, y, 3) ≈ ℓp_norm(x - y, 3) ≈ (3^3 + 4^3)^(1/3)

        x = randn(128)
        y = randn(128)

        @test ℓp_norm(x, 1) ≈ ℓ1_norm(x)
        @test ℓp_norm(x, 2) ≈ ℓ2_norm(x)
        @test ℓp_norm(x, 3) ≈ mapreduce(u -> abs(u)^3, +, x)^(1/3)
        @test ℓp(x, y, 1) ≈ ℓ1(x, y)
        @test ℓp(x, y, 2) ≈ ℓ2(x, y)
        @test ℓp(x, y, 3) ≈ mapreduce(u -> abs(u)^3, +, x - y)^(1/3)

        p = rand() + 1

        @test ℓp_norm(x, p) ≈ mapreduce(u -> abs(u)^p, +, x)^(1/p)
        @test ℓp(x, y, p) ≈ mapreduce(u -> abs(u)^p, +, x - y)^(1/p)
    end
end

@testset "Function space L^p distance and norm tests" begin
    Random.seed!(RANDOM_SEED)

    @testset "Compute L^1 distance and norm" begin
        interval = LSHFunctions.@interval(-π ≤ x ≤ π)
        f(x) = 0
        g(x) = 2

        @test L1_norm(g, interval) ≈ L1(f, g, interval) ≈ 4π

        g(x) = x

        @test L1_norm(g, interval) ≈ L1(f, g, interval) ≈ π^2

        f(x) = x
        g(x) = 2x.^2

        @test L1(f, g, interval) ≈ L1_norm(x -> f(x) - g(x), interval)
        @test L1(f, g, interval) ≈ quadgk(x -> abs(f(x) - g(x)), -π, π)[1]
    end

    @testset "Compute L^2 distance and norm" begin
        interval = LSHFunctions.@interval(-π ≤ x ≤ π)
        f(x) = 0
        g(x) = 2

        @test L2_norm(g, interval) ≈ L2(f, g, interval) ≈ √(8π)

        g(x) = x

        @test L2_norm(g, interval) ≈ L2(f, g, interval) ≈ √(2π^3 / 3)

        f(x) = x
        g(x) = 2x.^2

        @test L2(f, g, interval) ≈ L2_norm(x -> f(x) - g(x), interval)
        @test L2(f, g, interval) ≈ √quadgk(x -> abs2(f(x) - g(x)), -π, π)[1]
    end

    @testset "Compute L^p distance and norm" begin
        interval = LSHFunctions.@interval(-π ≤ x ≤ π)
        f(x) = 0
        g(x) = 2

        @test Lp_norm(g, interval, 1) ≈ Lp(f, g, interval, 1) ≈ L1(f, g, interval)
        @test Lp_norm(g, interval, 2) ≈ Lp(f, g, interval, 2) ≈ L2(f, g, interval)
        @test Lp_norm(g, interval, 3) ≈ Lp(f, g, interval, 3) ≈ (16π)^(1/3)

        g(x) = x

        @test Lp_norm(g, interval, 1) ≈ Lp(f, g, interval, 1) ≈ L1(f, g, interval)
        @test Lp_norm(g, interval, 2) ≈ Lp(f, g, interval, 2) ≈ L2(f, g, interval)
        @test Lp_norm(g, interval, 3) ≈ Lp(f, g, interval, 3) ≈ (π^4/2)^(1/3)

        f(x) = x
        g(x) = 2x.^2
        p = rand() + 1

        @test Lp(f, g, interval, p) ≈ Lp_norm(x -> f(x) - g(x), interval, p)
        @test Lp(f, g, interval, p) ≈
              quadgk(x -> abs(f(x) - g(x))^p, -π, π)[1]^(1/p)
    end
end

@testset "Cosine similarity tests" begin
    Random.seed!(RANDOM_SEED)

    @testset "Compute cosine similarity between Vectors" begin
        x = [1, 0, 1, 0]
        y = [0, 1, 0, 1]

        @test cossim(x, y) == 0

        y = [1, 0, 0, 0]

        @test cossim(x, y) == 1.0 / √2

        x = randn(20)

        @test cossim(x,   x) ≈  1
        @test cossim(x,  2x) ≈  1
        @test cossim(x,  -x) ≈ -1
        @test cossim(x, -2x) ≈ -1

        @test_throws ErrorException cossim(x, zero(x))
    end

    @testset "Compute cosine similarity between functions" begin
        interval = LSHFunctions.@interval(0 ≤ x ≤ 1)
        f(x) = (x ≤ 0.5) ? 1.0 : 0.0
        g(x) = (x ≤ 0.5) ? 0.0 : 1.0

        @test cossim(f, g, interval) ≈ 0
        @test cossim(f, f, interval) ≈ cossim(g, g, interval) ≈ 1
        @test cossim(f, x -> 2f(x), interval) ≈
              cossim(g, x -> 2g(x), interval) ≈ 1
        @test cossim(f, x -> -f(x), interval) ≈
              cossim(g, x -> -g(x), interval) ≈ -1
        @test_throws ErrorException cossim(f, x -> 0.0, interval)

        f(x) = x
        g(x) = x.^2

        @test L2_norm(f, interval) ≈ 1/√3
        @test L2_norm(g, interval) ≈ 1/√5
        @test inner_prod(f, g, interval) ≈ 1/4
        @test cossim(f, g, interval) ≈ 1/4 / (1/√3 * 1/√5)

        f, f_steps = create_step_function(10)
        g, g_steps = create_step_function(10)

        @test cossim(f, g, LSHFunctions.@interval(0 ≤ x ≤ 10)) ≈ cossim(f_steps, g_steps)
    end
end

@testset "Jaccard similarity tests" begin
    Random.seed!(RANDOM_SEED)

    @testset "Compute Jaccard similarity with Int64 sets" begin
        A = Set([1, 2, 3])
        B = Set([2, 3, 4])

        @test jaccard(A, A) == jaccard(B, B) == 1
        @test jaccard(A, B) == jaccard(B, A) == 2 / 4

        @test jaccard(A, Set()) == jaccard(B, Set()) == 0

        @test jaccard(A, Set([2])) == jaccard(B, Set([2])) == 1 / 3
        @test jaccard(A, Set([5])) == jaccard(B, Set([5])) == 0

        # Convention used in this module
        @test jaccard(Set(), Set()) == 0
    end

    @testset "Compute Jaccard similarity with String sets" begin
        A = Set(["a", "b", "c"])
        B = Set(["b", "c", "d"])

        @test jaccard(A, A) == jaccard(B, B) == 1
        @test jaccard(A, B) == jaccard(B, A) == 2 / 4

        @test jaccard(A, Set()) == jaccard(B, Set()) == 0

        @test jaccard(A, Set(["b"])) == jaccard(B, Set(["b"])) == 1 / 3
        @test jaccard(A, Set(["e"])) == jaccard(B, Set(["e"])) == 0

        # Convention used in this module
        @test jaccard(Set(), Set()) == 0
    end

    @testset "Compute Jaccard similarity between binary vectors" begin
        x = BitArray([true, false, true, true, false])
        y = BitArray([false, false, true, true, true])

        @test jaccard(x, y) == jaccard(y, x) == 2 / 4

        # When x and y are both full of zero bits, we define the
        # Jaccard similarity between them to be zero.
        x = falses(5)
        y = falses(5)
        @test jaccard(x, y) == 0
    end

    @testset "Compute weighted Jaccard similarity between Real vectors" begin
        x = [0.8, 0.1, 0.3, 0.4, 0.1]
        y = [1.0, 0.6, 0.0, 0.4, 0.5]

        @test jaccard(x, y) ==
              jaccard(y, x) ==
              (0.8+0.1+0.0+0.4+0.1) / (1.0+0.6+0.3+0.4+0.5)

        # Test Jaccard similarity between vectors with different dtypes
        x = mod.(rand(Int32, 20), 10)
        y = mod.(rand(Int64, 20), 10)
        @test jaccard(Float64.(x), Float64.(y)) ≈ jaccard(x, y)
        @test isapprox(jaccard(Float64.(x), Float64.(y)), jaccard(Float32.(x), y), atol=1e-8)
        @test isapprox(jaccard(Float64.(x), Float64.(y)), jaccard(x, Float32.(y)), atol=1e-8)
        @test jaccard(Float64.(x), Float64.(y)) ≈ jaccard(Float32.(x), Float64.(y))

        # Define the Jaccard similarity between pairs of Real vectors
        # to be zero.
        x = zeros(10)
        y = zeros(10)
        @test jaccard(x, y) == 0

        # Throw an error when any of the elements are negative, or when the
        # two vectors have different lengths.
        @test_throws(DimensionMismatch, jaccard(rand(5), rand(6)))
        @test_throws(ErrorException, jaccard(-ones(3), ones(3)))
    end

    @testset "Compute weighted Jaccard similarity between Sets" begin
        A = Set(["a", "b", "c"])
        B = Set(["b", "c", "d"])
        W = Dict("a" => 0.2, "b" => 2.4, "c" => 0.6, "d" => 1.8)

        @test jaccard(A, B, W) ≈
              jaccard(B, A, W) ≈
              (2.4 + 0.6) / (0.2 + 2.4 + 0.6 + 1.8)

        # We should throw an error when any of the weights are negative
        W["a"] = -1.0
        @test_throws(ErrorException, jaccard(A, B, W))
    end
end

@testset "Inner product similarity tests" begin
    Random.seed!(RANDOM_SEED)

    @testset "Compute ℓ^2 inner products between pairs of Vectors" begin
        x = [1, 2, 3, 4]
        y = [5, 6, 0, 0]

        @test inner_prod(x, x) ≈ dot(x, x) ≈ norm(x).^2 ≈
              1^2 + 2^2 + 3^2 + 4^2
        @test inner_prod(y, y) ≈ dot(y, y) ≈ norm(y).^2 ≈
              5^2 + 6^2
        @test inner_prod(x, y) ≈ dot(x, y) ≈ 1*5 + 2*6

        x = randn(128)
        y = randn(128)

        @test inner_prod(x, y) ≈ dot(x, y)
    end

    @testset "Compute L^2 inner products between pairs of functions" begin
        interval = LSHFunctions.@interval(-π ≤ x ≤ π)
        f(x) = 1
        g(x) = x

        @test inner_prod(f, f, interval) ≈ L2_norm(f, interval)^2 ≈ 2π
        @test inner_prod(g, g, interval) ≈ L2_norm(g, interval)^2 ≈ 2π^3 / 3
        @test isapprox(inner_prod(f, g, interval), 0.0; atol = 1e-15)

        f(x) = sin(x)
        g(x) = cos(x)

        @test inner_prod(f, f, interval) ≈ L2_norm(f, interval)^2 ≈
              quadgk(x -> sin(x)^2, -π, π)[1]
        @test inner_prod(g, g, interval) ≈ L2_norm(g, interval)^2 ≈
              quadgk(x -> cos(x)^2, -π, π)[1]

        # <f,g> = 0 via the identity sin(x)cos(x) = 1/2 sin(2x)
        @test isapprox(inner_prod(f, g, interval), 0.0; atol=1e-15)
    end
end
