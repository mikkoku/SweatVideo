function colortype(bg::AbstractArray{T}) where {S, T <: Color{S}}
    RGB{S}
end
# function addcolor(A, bg::AbstractArray{T}) where {S, T <: Color{S}}
#     TC = RGB{S}
#     colors = Dict{eltype(A), TC}(s => rand(TC) for s in unique(A))
#     delete!(colors, 0)
#     bg1 = view(bg, axes(A)...)
#     ((x, y) -> if iszero(x) TC(y) else colors[x] end).(A, bg1);
# end

function addcolor(::Type{T}, A) where T
    colors = Dict{eltype(A), T}(s => rand(T) for s in unique(A))
    delete!(colors, 0)
    (x, y) -> if iszero(x) T(y) else colors[x] end
end
function addcolor(::Type{T}, A::AbstractArray{Bool}) where T
    (x, y) -> if iszero(x) T(y) else zero(T) end
end
function addcolor(::Type{T}, A::AbstractArray{<:Color}) where T
    (x, y) -> x
end
# function addcolor(A::AbstractArray{Bool}, bg::AbstractArray{T}) where {S, T <: Color{S}}
#     bg1 = view(bg, axes(A)[1:3]...)
#     ((x, y) -> if iszero(x) T(y) else zero(T) end).(A, bg1);
# end
function catcolor(bg::AbstractArray{T}, AA...) where {S, T <: Color{S}}
    TC = RGB{S}
    size3 = min(size(bg, 3), minimum(size(A, 3) for A in AA))
    size4 = 1 + sum(size(A, 4) for A in AA)
    size3, size4
    ret = Array{TC, 4}(undef, size(bg)[1:2]..., size3, size4)
    ret[:,:,:,1] .= TC.(view(bg, :, :, 1:size3))
    i4 = 2
    for A in AA
        col = addcolor(TC, view(A, :, :, 1:size3, :))
        ret[:,:,:, i4:i4+size(A,4)-1] .= col.(view(A, :, :, 1:size3, :), view(bg, :, :, 1:size3, :))
        i4 += size(A, 4)
    end
    ret
end
# function addbackground(A, bg::AbstractArray{T}, col=zero(T)) where T
#     Aoi = broadcast((x, y) -> ifelse(x, col, y), A, @view bg[axes(A)[1:3]...])
#     Aoi
# end
#
# function applycolors(f, bg, col::AbstractArray{T}) where T
#     ((x, y) -> if iszero(x) T(y) else col[x] end).(f, @view bg[axes(f)...]);
# end
