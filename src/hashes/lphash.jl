import LinearAlgebra: norm
import LinearAlgebra.BLAS: ger!

"""
L^p distance LSH function.
"""
struct LpHash{T, A <: AbstractMatrix{T}} <: SymmetricLSHFunction{T}
	coeff :: A
	denom :: T
	shift :: Vector{T}
	power :: Int64
end

function LpHash{T}(input_length::Integer, n_hashes::Integer, denom::Real, power::Integer = 2) where {T}
	coeff = Matrix{T}(undef, n_hashes, input_length)
	shift = Vector{T}(undef, n_hashes)

	hashfn = LpHash{T,typeof(coeff)}(coeff, T(denom), shift, Int64(power))
	redraw!(hashfn)
	return hashfn
end

LpHash(args...; kws...) =
	LpHash{Float32}(args...; kws...)

# L1Hash and L2Hash convenience wrappers
#
# NOTE: at the moment, it is impossible to pass type parameters to either of these
# wrappers. That means that users are stuck with the default type for LpHash
# structs if they use either of the following methods, instead of the general
# LpHash constructor.
L1Hash(input_length :: Integer, n_hashes :: Integer, denom :: Real; kws...) where {T} =
	LpHash(input_length, n_hashes, denom, power = 1; kws...)

L2Hash(input_length :: Integer, n_hashes :: Integer, denom :: Real; kws...) where {T} =
	LpHash(input_length, n_hashes, denom, power = 2; kws...)

# Definition of the actual hash function
function (h::LpHash)(x::AbstractArray)
	coeff, denom, shift = h.coeff, h.denom, h.shift
	hashes = coeff * x
	hashes = @. hashes / denom + shift
	floor.(Int32, hashes)
end

# When the input x does not already have the appropriate type, perform a type
# conversion first so that we can hit BLAS
(h::LpHash{T})(x::AbstractArray{<:Real}) where {T <: LSH_FAMILY_DTYPES} =
	h(T.(x))

(h::LpHash{T})(x::AbstractArray{T}) where {T <: LSH_FAMILY_DTYPES} =
	invoke(h, Tuple{AbstractArray}, x)

#=
LSHFunction and SymmetricLSHFunction API compliance
=#
hashtype(::LpHash) = Int32
n_hashes(h::LpHash) = length(h.shift)

function redraw!(h::LpHash{T}) where T
	distr = begin
		if h.power == 1
			Cauchy(0,1)
		elseif h.power == 2
			Normal(0,1)
		else
			error("'power' must be 1 or 2")
		end
	end

	map!(_ -> T(rand(distr)), h.coeff, h.coeff)
	map!(_ -> rand(T), h.shift, h.shift)
end
