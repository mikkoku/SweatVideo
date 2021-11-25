struct SplitMeanDiff 
    mindiff::Float64
end
SplitMeanDiff() = SplitMeanDiff(0.2)
struct SplitRSS 
    minrss::Float64
    diffinstead::Bool
end
SplitRSS(minrss) = SplitRSS(minrss, false)
""" Transform grayscale to binary.
    Use gaussian blur to obtain "background".
    For each pixel find a change point in time.

    Not doing Image alignment/image registration.
    """
function do_split end



"This function is only used for explanation purposes"
function preprocess(A::AbstractArray{T,3}, blurradius=100, ::Type{S}=Float64) where {T,S}
    imgbg = estimatebackground(A, blurradius)
    #Ac = cat(imgbg, imgbg, imgbg, A, dims=3);
    Acc = Array{S, 3}(undef, size(A)[1:2]..., 3+size(A, 3))
    Acc[:,:,1:3] .= oneunit(S)
    Acc[:,:,4:end] .= S.(clamp.(A ./ imgbg, 0.0, 1.0))
    #Acc = cat(ones(T, size(imgbg)..., 3), T.(clamp.(A ./ imgbg, 0.0, 1.0)), dims=3);
    #Acc = T.(Ac ./ imgbg);
    Acc
end

function estimatebackground(A, blurradius)
    imfilter(A[:,:,1], Kernel.gaussian(blurradius));
end
function find_changepoints(m, A::AbstractArray{T,3}, imgbg) where T
    S = Float64
    s3 = size(A, 3) + 3
    Acc = Array{S, 1}(undef, s3)
    Acc[1:3] .= 1.0
    function f(x, y)
        Acc[4:end] .= clamp.(@view(A[x, y, :]) ./ imgbg[x, y], 0.0, 1.0)
        findsplitforpixel(m, Acc)
    end
    [f(x, y) for x in axes(A, 1), y in axes(A, 2)]
end
function do_split(A; blurradius=100, mindiff=0.2)
    do_split(SplitMeanDiff(mindiff), A, blurradius)
end
function do_split(method, A :: AbstractArray{<:Color}, blurradius::Real)
    bg = estimatebackground(A, blurradius)
    Asplit = find_changepoints(method, A, bg)
    do_split(method, A, Asplit)
end
function do_split(method, A, Asplit :: AbstractArray{<:Tuple})
    broadcast(split2binary, Ref(method), Asplit, reshape(1:size(A, 3), (1,1,:)));
end
function find_split(method, A, blurradius=100)
    find_changepoints(method, A, blurradius)
end

# function find_split_threshold(A, blurradius)
#     #Acc = preprocess(A, blurradius)
#     #@time Asplit = mapslices(findsplitforpixel, Acc, dims=3);
#     @time Asplit = find_Asplit(A, blurradius)
#     #A3 = broadcast(dosplit2, A, Asplit, reshape(1:size(A, 3), (1,1,size(A,3))), mindiff);
#     A3 = broadcast(split2threshold, Asplit, reshape(1:size(A, 3), (1,1,size(A,3))));
#     A3
# end

function findsplitrss(x)
    x0 = 0.0
    x1 = Float64(sum(x))
    xx0 = 0.0
    xx1 = Float64(sum(abs2, x))
    n = length(x)
    nullrss = xx1 - x1^2/n

    minss = nullrss
    mini = 0
    meandiff = 0.0
    for i in 1:(n-1)
        xi = Float64(x[i])
        x0 += xi
        x1 -= xi
        xx0 += xi^2
        xx1 -= xi^2
        ss = xx0 - x0^2/i + xx1 - x1^2/(n-i)
        if ss < minss && x0/i > x1/(n-i)
            minss = ss
            meandiff = x0/i - x1/(n-i)
            mini = i
        end
    end
    meandiff, minss, nullrss, mini
end

function findsplitforpixel(m::SplitRSS, x)
    meandiff, rss, nullrss, mini = findsplitrss(x)
    if m.diffinstead
        mini, meandiff
    else
        mini, (nullrss-rss)/(rss/(length(x)-2))
    end
end

function split2binary(m::SplitRSS, split, j)
    i, diff = split
    i -= 3
    if j > i && diff > m.minrss #&& i != 1
        true
    else
        false
    end
end
function split2threshold(split, j)
    i, diff = split
    i -= 3
    if j > i
        diff
    else
        zero(diff)
    end
end

""" Difference in means and sum of variances
"""
function meanandvar(x0, x1, xx0, xx1, i, n)::Tuple{Float64, Float64}
    mean = x0 / i - x1 / (n-i)
    var = (xx0/i - (x0/i)^2) + (xx1/(n-i) - (x1/(n-i))^2)
         # var(x[1:i], corrected=false) + var(x[i+1:n], corrected=false)
    #var = (xx0*i - x0^2)/i^2 + (xx1*(n-i) - x1^2)/(n-i)^2
    #mean = x0 * (n-i) - x1 * i
    #var = (xx0*i - x0^2)*(n-i)^2 + (xx1*(n-i) - x1^2)*i^2
    mean, var
end

function findsplitvar(x)
    x0 = 0.0
    x1 = Float64(sum(x))
    xx0 = 0.0
    xx1 = Float64(sum(abs2, x))
    n = length(x)

    minvar = xx1
    mindiff = x1
    mini = 0
    for i in 1:(n-1)
        xi = Float64(x[i])
        x0 += xi
        x1 -= xi
        xx0 += xi^2
        xx1 -= xi^2
        newdif, newvar = meanandvar(x0, x1, xx0, xx1, i, n)
        if newvar < minvar
            minvar = newvar
            mindiff = newdif
            mini = i
        end
    end
    mini, mindiff, minvar
end

function findsplitforpixel(::SplitMeanDiff, x)
    i, mindiff = findsplitvar(x)
    i, mindiff
end

function split2binary(m::SplitMeanDiff, split, j)
    i, diff = split
    i -= 3
    if j > i && diff > m.mindiff #&& i != 1
        true
    else
        false
    end
end
