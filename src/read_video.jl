# To convert video to png
# run(`ffmpeg -r 1 -i $folder/$file.avi -r 1 $folder/png/$file%03d.png`)

# using FileIO

"""
    Reads a video.
    Picks the red channels since all the channels were equal.
    Returns Array{Gray{T}, 3}
"""
function readvideo(filename)
    f = openvideo(filename)
    A1 = []
    while !eof(f)
        push!(A1, read(f))
    end
    # make A1 typed
    function checkgray(x)
        red(x) == green(x) == blue(x)
        Gray(red(x))
    end
    catfun([x for x in A1], checkgray)
end
function catfun(As::AbstractArray{S}, fun) where {TE, T <: Color{TE}, S <: AbstractArray{T}}
    AA = Array{Gray{TE}, 3}(undef, size(As[1])..., length(As))
    for (i, A) in enumerate(As)
        v = view(AA, :, :, i)
        @. v = fun(A)
    end
    AA
end

