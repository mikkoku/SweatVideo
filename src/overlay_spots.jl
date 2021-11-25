# overlay spots on image

function setpixel!(img, x, y, col)
    setpixel!(img, round(Int, x), round(Int, y), col)
    setpixel!(img, round(Int, x)+1, round(Int, y), col)
    setpixel!(img, round(Int, x), round(Int, y)+1, col)
    setpixel!(img, round(Int, x)-1, round(Int, y), col)
    setpixel!(img, round(Int, x), round(Int, y)-1, col)
end
function setpixel!(img, x::Int, y, col)
    if checkbounds(Bool, img, x, y)
        img[x, y] = col
    end
end
function overlay_spots(A, df, col; kwargs...)
    A1 = copy(A)
    overlay_spots!(A1, df, col; kwargs...)
    A1
end
function overlay_spots!(A::AbstractArray{<:Any, 3}, df::CSVFiles.CSVFile, col; kwargs...)
    overlay_spots!(A, collect(df), col; kwargs...)
end
function extract_frame(df::AbstractArray{T}, frame) where {NAMES, T <: NamedTuple{NAMES}}
    if :Centroid_X in NAMES
        [(x.Centroid_Y, x.Centroid_X, x.AreaInPixels) for x in df if x.Frame==frame && x.Centroid_X != 0]
    elseif :area in NAMES
        [(x.y, x.x, x.area) for x in df if x.frame==frame && x.x != 0]
    end
end
function overlay_spots!(A::AbstractArray{<:Any, 3}, df::AbstractArray{<:NamedTuple}, col; kwargs...)
    #(:x, :y, :area, :frame)
    for frame in 1:size(A, 3)
        d = extract_frame(df, frame)
        overlay_spots!((@view A[:,:,frame]), d, col; kwargs...)
    end
end
function overlay_spots!(A::AbstractArray{T, 2}, xyarea, col::T; d=-1.0) where T
    #d = get(kwargs, :d, Inf)
    for (i, (x, y, area)) in enumerate(xyarea)
        r = sqrt(area/pi) + 0.5
        circlen = pi*r
        if tooclose(xyarea, i, d)
            col1 = T(0.5, 0.5, 1.0)
        else
            col1 = col
        end
        for angle in range(0, pi, length=ceil(Int, circlen))
            dx = r*cos(angle)
            dy = r*sin(angle)
            setpixel!(A, x+dx, y+dy, col1)
            setpixel!(A, x-dx, y-dy, col1)
        end
    end
end

function tooclose(p, i::Int, R)
    x0, y0 = p[i]
    R2 = Float64(R^2)
    for i1 in eachindex(p)
        if i != i1
            x1, y1 = p[i1]
            d2 = (x1-x0)^2 + (y1-y0)^2
            if d2 < R2
                return true
            end
        end
    end
    false
end
