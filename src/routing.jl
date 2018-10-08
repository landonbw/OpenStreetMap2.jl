struct DijkstraState
    parents::Vector{Int}
    dists::Vector{Float64}
end

function shortestpath!(
        g::LightGraphs.DiGraph,
        srcs::Vector{Int},
        distmx::AbstractMatrix{Float64},
        ds::DijkstraState,
        threshold::Float64 = Inf
    )
    fill!(ds.dists, Inf); ds.dists[srcs] = zero(Float64)
    fill!(ds.parents, 0)
    H = DataStructures.PriorityQueue{Int,Float64}()    
    for v in srcs; H[v] = ds.dists[v] end
    while !isempty(H)
        u, _ = DataStructures.dequeue_pair!(H)
        @assert ds.dists[u] < Inf
        for v in LightGraphs.outneighbors(g, u)
            distv = ds.dists[u] + distmx[u,v]
            if distv < min(threshold, ds.dists[v])
                H[v] = ds.dists[v] = distv; ds.parents[v] = u
            end
        end
    end
    for s in srcs; @assert ds.parents[s] == 0 end
    ds
end

function shortestpath!(
        network::OSMNetwork,
        srcs::Vector{Int},
        ds::DijkstraState,
        threshold::Float64 = Inf
    )
    shortestpath!(network.g, srcs, network.distmx, ds, threshold)
end

function shortestpath(
        network::OSMNetwork,
        srcs::Vector{Int},
        threshold::Float64 = Inf
    )
    parents = zeros(Int,LightGraphs.nv(network.g))
    dists = fill(Inf,LightGraphs.nv(network.g))
    shortestpath!(network, srcs, DijkstraState(parents,dists), threshold)
end

"""
find the nearest osm node that is on a roadway to the specified lat lon tuple
"""
function nearestnode(network::OSMNetwork, coords::Tuple{Float64, Float64})
    lat = coords[1]
    lon = coords[2]
    roadnodes = values(network.nodeid)
    idxinset = findall(x -> x in roadnodes, network.data.nodes.id)
    nodes = network.data.nodes.id[idxinset]
    nodelats = network.data.nodes.lat[idxinset]
    nodelons = network.data.nodes.lon[idxinset]
    distances = [LinearAlgebra.norm(collect(coords) - [a, b]) for (a,b) in zip(nodelats, nodelons)]
    nearest = nodes[findfirst(distances .== minimum(distances))]
    return nearest
end