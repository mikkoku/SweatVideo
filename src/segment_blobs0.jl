# Segment frames independently for explanation purposes only.

function segment_blobs_(mask, fun!)
    f = Int32.(mask)
    _, clusterid = doclustering!(@view f[:,:,1])
    for frame in 2:size(f, 3)
        println(frame)
        _, clusterid = doclustering!(view(f, :,:,frame)) #, clusterid)
        fun!((@view f[:,:,frame]), @view f[:,:,frame-1])
    end
    f
end
function segment_blobs0(mask)
    segment_blobs_(mask, (_,_) -> nothing)
end
