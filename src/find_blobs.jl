# Find blobs in frame
# Find connected components in a binary mask
# Label components 1 ... number of compoents

# function doclustering(f)
#     doclustering(copy(f))
# end
"""
    Find connected components in the 2d binary image given as a matrix of integers,
    which should only be 0 or 1.
    Returns the input matrix with values replaced by componentids 1:maxid, and maxid.
"""
function doclustering!(f, clusteridstart=one(eltype(f)))
    f1 = f
    clusterid, dict = findclusters1!(f1, clusteridstart)
    d, key = mergeclusters(dict)
    clusterid = changeclusters!(f1, d, key)
    f1, clusterid
end


function findclusters1!(f1::AbstractArray{T}, clustermax::T) where T
    # Connect each node to its left or top neighbour
    # If left and top both exists then make a connection
    edges = Set{Tuple{T,T}}()
    clusterid = clustermax + one(T)
    i = 1
    for j in 2:size(f1, 2)
        cur = f1[i, j]
        if cur != 0
            top = f1[i, j-1]
            if top != 0
                cur = top
            else
                cur = clusterid
                clusterid += one(T)
            end
            f1[i, j] = cur
        end
    end
    j = 1
    for i in 2:size(f1, 1)
        cur = f1[i, j]
        if cur != 0
            left = f1[i-1, j]
            if left != 0
                cur = left
            else
                cur = clusterid
                clusterid += one(T)
            end
            f1[i, j] = cur
        end
    end
    for j in 2:size(f1, 2)
        for i in 2:size(f1, 1)
            cur = f1[i, j]
            if cur != zero(T)
                left = f1[i-1, j]
                top = f1[i, j-1]
                if left != 0 && top != 0
                    cur = left
                    if left != top
                        push!(edges, (top, cur))
                        #push!(edges, (cur, top))
                    end
                elseif top != 0
                    cur = top
                elseif left != 0
                    cur = left
                else
                    cur = clusterid
                    clusterid += one(T)
                end
                f1[i, j] = cur
            end
        end
    end
    clusterid, edges
end
function compresskeys(edges, vertexindex, vertexindex2)
    key = 1
    for (a,b) in edges
        for k in (a,b)
            if !haskey(vertexindex, k)
                vertexindex[k] = key
                push!(vertexindex2, k)
                @assert vertexindex2[key] == k
                key += 1
            end
        end
    end
end
function mergeclusters(edges::Set{Tuple{T, T}}) where T
    vertexindex = Dict{T, Int}() # used to compress arbitrary keys to 1:maxid
    vertexindex2 = Vector{T}() # 1:maxid to old keys
    compresskeys(edges, vertexindex, vertexindex2) # to use with SimpleGraph
    nnodes = length(vertexindex2)
    # Maybe there is some more complicated graph that supports Int32
    g = SimpleGraph(nnodes)
    for (a,b) in edges
        add_edge!(g, vertexindex[a], vertexindex[b])
    end
    components = connected_components(g)

    # Make a dictionary (old key => merged clusterid)
    dict = Dict{T, T}( 0 => 0)
    key = one(T)
    for set in components
        for elem in set
            dict[vertexindex2[elem]] = key
        end
        key += one(T)
    end
    dict, key
end
function changeclusters!(f1, dict, newclusterstart::T) where T
    key = newclusterstart
    for i in eachindex(f1)
        # f1[i] = get!(dict, f1[i]) do
        #     key += one(T)
        #     key
        # end
        f1i = f1[i]
        # Accessing the dict is costly
        # Usually there are a lot of zeros and then there is no need for the dict.
        # Should maybe change dict to Vector
        # Or Vector for small + dict for others?
        if f1i != 0
            if !haskey(dict, f1i)
                key += one(T)
                dict[f1i] = key
            end
            f1[i] = dict[f1i]
        end
    end
    key
end

