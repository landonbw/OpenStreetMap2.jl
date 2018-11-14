struct DijkstraState
    parents::Vector{Int}
    dists::Vector{Float64}
end

# function shortestpath!(
#         g::LightGraphs.DiGraph,
#         srcs::Vector{Int},
#         distmx::AbstractMatrix{Float64},
#         ds::DijkstraState,
#         threshold::Float64 = Inf
#     )
#     fill!(ds.dists, Inf); ds.dists[srcs] = zero(Float64)
#     fill!(ds.parents, 0)
#     H = DataStructures.PriorityQueue{Int,Float64}()
#     for v in srcs; H[v] = ds.dists[v] end
#     while !isempty(H)
#         u, _ = DataStructures.dequeue_pair!(H)
#         @assert ds.dists[u] < Inf
#         for v in LightGraphs.outneighbors(g, u)
#             distv = ds.dists[u] + distmx[u,v]
#             if distv < min(threshold, ds.dists[v])
#                 H[v] = ds.dists[v] = distv; ds.parents[v] = u
#             end
#         end
#     end
#     for s in srcs; @assert ds.parents[s] == 0 end
#     ds
# end

# function shortestpath!(
#         network::OSMNetwork,
#         srcs::Vector{Int},
#         ds::DijkstraState,
#         threshold::Float64 = Inf
#     )
#     shortestpath!(network.g, srcs, network.distmx, ds, threshold)
# end

# function shortestpath(
#         network::OSMNetwork,
#         srcs::Vector{Int},
#         threshold::Float64 = Inf
#     )
#     parents = zeros(Int,LightGraphs.nv(network.g))
#     dists = fill(Inf,LightGraphs.nv(network.g))
#     shortestpath!(network, srcs, DijkstraState(parents,dists), threshold)
# end

"""
Find the shortest path between a source and destination
"""
function shortestpath(network::OSMNetwork, source::Int64, destination::Int64, distmx=network.distmx)
    return LightGraphs.enumerate_paths(LightGraphs.dijkstra_shortest_paths(network.g, source, distmx), destination)
end

function shortestpath(network::OSMNetwork, source::Tuple{Float64, Float64}, destination::Tuple{Float64, Float64})
    src = network.nodesource[treenearestnode(network, source)]
    dst = network.nodesource[treenearestnode(network, destination)]
    return shortestpath(network, src, dst)
end

function quickestpath(network::OSMNetwork, source::Int64, destination::Int64)
    speedmatrix = network.distmx .* constructspeedmatrix(network)
    if source == destination
        return [], 0, 0
    end
    
    path = shortestpath(network, source, destination, speedmatrix)
    time = 0
    dist = 0
    for i=1:length(path)-1
        time+=speedmatrix[path[i], path[i+1]]
        dist+=network.distmx[path[i], path[i+1]]
    end
    # time = 10
    if time == dist == 0
        time = Inf
        dist = Inf
    end
    return path, time, dist
end

function quickestpath(network::OSMNetwork, source::Tuple{Float64, Float64}, destination::Tuple{Float64, Float64})
    src = network.nodesource[treenearestnode(network, source)]
    dst = network.nodesource[treenearestnode(network, destination)]
    return quickestpath(network, src, dst)
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

"""
Creates the speed matrix that can be used to determine time to travel to a given location
note that because julia's sparse arrays don't currently support broacasted division very well
we the matrix actually stores the inverse speed.
"""
function constructspeedmatrix(network::OSMNetwork, access::Dict{String,Symbol}=ACCESS["all"])
    tags(w::Int) = get(network.data.tags, w, Dict{String,String}())
    lookup(tags::Dict{String,String}, k::String) = get(tags, k, "")
    hasaccess(w::Int) = get(access, lookup(tags(w),"highway"), :no) != :no
    ishighway(w::Int) = haskey(tags(w), "highway")
    isreverse(w::Int) = lookup(tags(w),"oneway") == "-1"
    wayids = filter(hasaccess, filter(ishighway, collect(keys(network.data.ways))))

    edgestart = Vector{Int64}()
    edgeend = Vector{Int64}()
    edgespeed = Vector{Float64}()
    for w in wayids
        way = network.data.ways[w]
        waytype = network.data.tags[w]["highway"]
        wayclass = get(ROADCLASSES, waytype, :service)
        speed = get(SPEEDLIMIT_RURAL, wayclass, 5)
        for n in 2:length(way)
            push!(edgestart, way[n-1])
            push!(edgeend, way[n])
            push!(edgespeed, speed)
        end
    end
    # return edgestart, edgeend, edgespeed
    es = get.(Ref(network.nodesource), edgestart, 0)
    ee = get.(Ref(network.nodesource), edgeend, 0)
    speedmx = SparseArrays.sparse([es;ee], [ee;es], 1.0./[edgespeed;edgespeed])
end
