# Morphological open
""" For dim != 2, this function still creates a 2d circle.
"""
function kernelcircle(r, dim=2)
    n = 2 * ceil(Int, r) + 1
    A = centered(ones(Int32, n, n, ones(Int, dim-2)...))
    r2 = r^2
    for I in CartesianIndices(A)
        x, y = Tuple(I)
        if x^2 + y^2 > r2
            A[I] = 0
        end
    end
    A
end

function dilation(A::AbstractArray{T, D}, r, alg=ImageFiltering.Algorithm.FIR()) where {D, T}
    k = kernelcircle(r, D)
    imfilter(A, k, alg) .>= 0.5
end
function erosion(A::AbstractArray{T, D}, r, alg=ImageFiltering.Algorithm.FIR()) where {D, T}
    k = kernelcircle(r, D)
    imfilter(A, k, alg) .>= sum(k) - 0.5
end
function closing(A, r)
    A1 = dilation(A, r)
    erosion(A1, r)
end
function opening(A::AbstractArray{T, D}, r, alg) where {D, T}
    k = kernelcircle(r, D)
    A1 = imfilter(A, k, alg) .>= sum(k) - 0.5
    imfilter(A1, k, alg) .>= 0.5
end
function opening(A, r)
    opening(A, r, ImageFiltering.Algorithm.FIR())
end

function internalgradient(A::AbstractArray{T, D}) where {D, T}
    Bool.(A - erosion(A, 1))
end
function externalgradient(A::AbstractArray{T, D}) where {D, T}
    Bool.(dilation(A, 1) - A)
end
function gradient(A::AbstractArray{T, D}) where {D, T}
    Bool.(dilation(A, 1) - erosion(A, 1))
end
