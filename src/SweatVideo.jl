module SweatVideo

using ColorTypes
using VideoIO
using ImageFiltering
using Graphs
using CSVFiles, FileIO
# using FFTW

@assert 1==1
# const minimum_blob_size = 350 #35
include("read_video.jl") 
include("find_blobs.jl") 
include("changepoint.jl")
include("morphology.jl")
include("segment_blobs0.jl")
# include("grow_blobs_gpu.jl")
include("grow_blobs.jl")
include("overlay_spots.jl")
include("colorutil.jl")
#include("util/read_glands.jl")
#include("datafiles.jl") # in sweat metapaackge
include("extract_glands_table.jl")
export readpngs, readvideo, readcsv,
    colortype,
    find_split, do_split,
    catcolor, #addcolor, colortype,
    internalgradient, externalgradient, gradient,
    opening, closing,
    segment_blobs,
    # segment_blobs2,
    segment_blobs0,
    # segment_blobs_gpu,
    overlay_spots,
    align_frames,
#    readglands,
    datalist, paths,
    extractglands
# function __init__()
#     init() # GPU context
# end
end # module
