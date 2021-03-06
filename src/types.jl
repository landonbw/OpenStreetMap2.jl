include("protobuf/OSMPBF.jl")

const OSMPBFFileBlock = Union{OSMPBF.HeaderBlock, OSMPBF.PrimitiveBlock}

struct OSMNodes
    id::Vector{Int}
    lon::Vector{Float64}
    lat::Vector{Float64}

    OSMNodes() = new([],[],[])
end

struct OSMData
    header::OSMPBF.HeaderBlock
    nodes::Dict{Int, Tuple{Float64, Float64}}
    ways::Dict{Int,Vector{Int}} # osm_id -> way_refs
    nodeparent::Dict{Int, Int} # node_id -> way osm_id
    relations::Dict{Int,Dict{String,Any}} # osm_id -> relations
    tags::Dict{Int,Dict{String,String}} # osm_id -> tags
    destinations::Dict{Tuple{String, String}, Array{Float64, 2}} # hold destinations for a given key

    OSMData() = new(
        OSMPBF.HeaderBlock(), Dict(), Dict(), Dict(), Dict(), Dict(), Dict()
    )
end
