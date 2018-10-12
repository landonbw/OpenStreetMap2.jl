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
    roadnodes = collect(values(network.nodeid))
    # idxinset = findall(x -> x in roadnodes, network.data.nodes.id)
    # nodes = get.(network.data.nodes, 
    # nodes = network.data.nodes.id[idxinset]
    latlons = get.(network.data.nodes, roadnodes, 99999)
    nodelats = [a[1] for a in latlons]
    nodelons = [a[2] for a in latlons]
    distances = [LinearAlgebra.norm(collect(coords) - [a, b]) for (a,b) in zip(nodelats, nodelons)]
    # println(minimum(distances))
    nearest = roadnodes[findfirst(distances .== minimum(distances))]
    return nearest
end

function treenearestnode(network::OSMNetwork, coords::Tuple{Float64, Float64})
    lat = coords[1]
    lon = coords[2]
    idx, dist = NearestNeighbors.knn(network.nntree, [lat, lon], 1)
    # println(dist)
    return network.connectednodes[idx[1]]
end