# Input binary video
# Output different ids for different sweat glands production
# Start from first frame, 
# grow spots frame by frame, 
# merge spots if they are too small (sometimes sweat jumps over some pixels)

@inline function kernelvote4(q, mask, output, x, y)
    q0 = @inbounds q[x, y];
    if (@inbounds mask[x, y] == 0) return 0 end

    if (q0 != 0) 
        @inbounds output[x, y] = q0;
        return 0;
    end
    kernelvote4inner(q, mask, output, x, y)
end
function sort4(i1, i2, i3, i4)
    # Probably bitonic sort
    j1 = min(i1, i2);
    j2 = max(i1, i2);
    j3 = min(i3, i4);
    j4 = max(i3, i4);
    i2     = max(j1, j3);
    j1     = min(j1, j3);
    i3     = min(j2, j4);
    j4     = max(j2, j4);
    j2 = min(i2, i3);
    j3 = max(i2, i3);
    j1, j2, j3, j4
end
function kernelvote4inner(q, mask, output, x, y)
    w, h = size(q)
    i1 = x < w && mask[x + 1, y + 0] != 0 ? q[x + 1, y + 0] : 0
    i2 = x > 1 && mask[x - 1, y + 0] != 0 ? q[x - 1, y + 0] : 0
    i3 = y < h && mask[x + 0, y + 1] != 0 ? q[x + 0, y + 1] : 0
    i4 = y > 1 && mask[x + 0, y - 1] != 0 ? q[x + 0, y - 1] : 0
    
    j1, j2, j3, j4 = sort4(i1, i2, i3, i4)
    o = 0;
    if (j1 != 0 && j1 == j2) o = j2;
    elseif (j3 != 0) o = j3;
    elseif (j4 != 0) o = j4;
    end
    if (o != 0)
        output[x, y] = o;
        return 1
    end
    0
end

function _iter(A, mask, tmp)
    # amask = convert(Array, mask)
    # aA = convert(Array, A)
    b1 = A
    b2 = copy!(tmp, A)#copy(A)
    i = 0
    while i < 100
        changed = 0
        for y in axes(A, 2)
            for x in axes(A, 1)
                changed += kernelvote4(b1, mask, b2, x, y)
            end
        end

        if changed == 0
            break
        end
        i += 1
        b1, b2 = b2, b1
    end
    return i, b1
end

function segment_blobs(mask)
    f = Int32.(mask)
    tmp = Matrix{Int32}(undef, size(f, 1), size(f, 2))
    tmp2 = similar(tmp)
    _, clusterid = doclustering!(view(f, :,:,1))
    for frame in 2:size(f, 3)
        #println(frame)
        _, clusterid = doclustering!(view(f, :,:,frame)) #, clusterid)
        #return f[:,:,frame], f[:,:,frame-1]
        matchclusterids!(view(f, :,:,frame), view(f, :,:,frame-1), tmp, tmp2)
    end
    println()
    f
end

function matchclusterids_part1(f2, f1)
    matchclusterids_part1!(similar(f1), f2, f1)
end
function matchclusterids_part1!(f1c, f2, f1)
    #mask = @. Int32(f2 != 0)
    maxid = max(maximum(f2), maximum(f1))
    toosmall, new = computetoosmallandnew(f2, f1, maxid)
    # Remove small clusters from f1
    # Copy new clusters

    newids = Dict{Int, Int}()
    # f1c = similar(f1)
    for i in eachindex(f1c)
        a = f1[i]
        b = f2[i]
        if b != 0
            if new[b]
                c = get!(newids, b, maxid+1)
                if c == maxid+1
                    maxid += one(maxid)
                end
                f1c[i] = c
                # f1c[i] = get!(newids, b) do
                #     maxid += 1
                #     maxid
                # end
            elseif a == 0 || !toosmall[a]
                f1c[i] = a
            else
                f1c[i] = zero(eltype(f1))
            end
        else
            @assert a == 0
        end
    end
    f1c
end    


function matchclusterids!(f2, f1, tmp, tmp2)
    f1c = matchclusterids_part1!(tmp, f2, f1)

    #println(sizesnew, sizesold)
    mask = f2
    i, B = _iter(f1c, mask, tmp2)
    print(i, ",") #, ":", count(!iszero, mask)
    copy!(f2, B)
end

# Count the number of pixels in each blob of A
#  # (And the number of pixels that are also in B)
# Id of the largest (too small) blob in B or 0 otherwise.
#  Too small = all but largest
function computetoosmallandnew(f2::AbstractArray{T}, f1::AbstractArray{T}, maxid::T) where T
    @assert maxid < 1_000_000
    toosmall = falses(maxid)
    new = falses(maxid)

    # Create a Dict with new cluster ids -> Dict(old cluster ids -> count)
    dict = [Dict{T, Int}() for i in 1:maxid]
    for (a,b) in zip(f1, f2)
        if a != 0 #&& b != 0
            d = dict[b]
            count = get!(d, a, 0)
            if count <= minimum_blob_size + 2# No need to count more than used in the next for loop
                d[a] = count+1
            end
        end
    end
    # The Vector{Dict} dict could be simplified to two Vector{Int}:s maybe:
    # testi = reduce(vcat, collect.(keys.(dict)))
    # @assert allunique(testi)
    for (i, d) in enumerate(dict)
        if length(d) == 0
            new[i] = true
        else
            count, key = maximum((count, k) for (k, count) in d)
            for (k, v) in d
                if v < minimum_blob_size && (v, k) < (count, key)
                    toosmall[k] = true
                end
            end
        end
    end
    toosmall, new
end
