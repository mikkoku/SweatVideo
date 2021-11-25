# Make a dataset with blob glandsizes per fram
# BlobID, first frame mean (x, y), all frames (size)

function extractglandsdataframe(A::AbstractArray{T}) where T <: Integer
    minimum_blob_size = 35 #sweat.minimum_blob_size
    # Create a Dict with new cluster ids -> Dict(old cluster ids -> count)
    dicts = [Dict{T, NTuple{3, Int}}() for _ in axes(A, 3)]
    for frame in axes(A, 3)
        dict = dicts[frame]
        for x in axes(A,1), y in axes(A, 2)
            a = A[x, y, frame]
            if a != 0
                count, sumx, sumy = get!(dict, a) do
                    (0,0,0)
                end
                dict[a] = (count+1, sumx+x, sumy+y)
            end
        end
    end
    seen = Dict{T, Any}()
    for (frame, dict) in enumerate(dicts)
        for (id, stuff) in dict
            (count, sumx, sumy) = stuff
            if count >= minimum_blob_size
                if !haskey(seen, id)
                    seen[id] = ((sumx/count, sumy/count),[])
                end
                a = seen[id]
                push!(a[2], (frame, count))
            end
        end
    end
    seen
end

# Remove glands that don't exist on last frame
# Area needs to grow after one half of the lifetime
function extractglands(A)
    a = extractglandsdataframe(A)
    glands2 = NamedTuple{(:id, :y, :x, :frame, :area)}[]
    id = 0

    foreach(values(a)) do (xy, t)
        lastframe, lastarea = t[end]
        if length(t) >= 2 && lastframe == size(A, 3)
            changes = count(i -> t[i][2] != t[i+1][2], 1:length(t)-1)
            if 4changes >= length(t) || lastarea >= 100
                id += 1
                append!(glands2, [NamedTuple{(:id, :y, :x, :frame, :area)}((id, xy..., t1...)) for t1 in t])
            end
        end
    end
    glands2
end

function split(f, A::TA) where TA
    d = Vector{TA}()
    index = Dict()
    for a in A
        fa = f(a)
        i = get!(index, fa) do
            push!(d, similar(A, 0))
            length(d)
        end
        push!(d[i], a)
    end
    d
end
# Remove glands that are too close to larger glands
function removetooclose(A, R)
    As = split(x -> x.frame, A)
    B = similar(A, 0)
    N = 0
    R2 = R^2
    d2((x1, y1), (x2, y2)) = (x1-x2)^2 + (y1-y2)^2
    foreach(As) do A
        xy = [(x.x, x.y) for x in A]
        for i in eachindex(xy)
            dists = [d2(x, xy[i]) for x in xy]
            competitors = [(x.area, i) for (i, x) in enumerate(A) if dists[i] < R2]
            if length(competitors) >= 2
                _, j = maximum(competitors)
                if j == i
                    push!(B, A[i])
                else
                    N += 1
                end
            else
                push!(B, A[i])
            end
        end
    end
    if N != 0
        println("Removed $N points being too close")
    end
    B, N
end
