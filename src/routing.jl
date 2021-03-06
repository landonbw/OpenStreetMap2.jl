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

function testthings(a=SPEEDLIMIT_URBAN)
    return a
end

"""
Find the shortest path between a source and destination
"""
function shortestpath(network::OSMNetwork, source::Int64, destination::Int64, distmx=network.distmx; warn=true)
    path = LightGraphs.enumerate_paths(LightGraphs.dijkstra_shortest_paths(network.g, source, distmx), destination)
    if (length(path) < 1) && (source != destination)
        if warn
            @warn "No path found from $source to $destination, attempting on undirected graph"
        end
        path = LightGraphs.enumerate_paths(LightGraphs.dijkstra_shortest_paths(LightGraphs.SimpleGraph(network.g), source, distmx), destination)
    end
    return path
end

function shortestpath(network::OSMNetwork, source::Tuple{Float64, Float64}, destination::Tuple{Float64, Float64}; warn=true)
    src = network.nodesource[treenearestnode(network, source)]
    dst = network.nodesource[treenearestnode(network, destination)]
    return shortestpath(network, src, dst, warn=warn)
end

function pathtimedist(path::Array{Int, 1}, speedmx::SparseArrays.SparseMatrixCSC{Float64, Int64}, distmx::SparseArrays.SparseMatrixCSC{Float64, Int64})
    time = Array{Float64, 1}(undef, length(path)-1)
    dist = Array{Float64, 1}(undef, length(path)-1)
    for i=1:length(path)-1
        time[i] = speedmx[path[i], path[i+1]]
        dist[i] = distmx[path[i], path[i+1]]
    end
    return time, dist
end

function recalcSpeedMatrix(network::OSMNetwork, speeddict::Union{Dict{String, Float64}, Dict{Symbol, Float64}}=SPEEDLIMIT_URBAN)
    network.speedmatrix = constructspeedmatrix(network, speeddict)
end


function quickestpath(network::OSMNetwork, source::Int64, destination::Int64,
    speeddict::Union{Dict{String, Float64}, Dict{Symbol, Float64}}=SPEEDLIMIT_URBAN; warn=true)
    if size(network.speedmatrix)[1] < 1        
        recalcSpeedMatrix(network, speeddict)
    end
    speedmatrix = network.distmx .* network.speedmatrix
    if source == destination
        return [], [0], [0]
    end
    path = shortestpath(network, source, destination, speedmatrix, warn=warn)
    if length(path) < 1
        return [], [0], [0]
    end
    # time = Array{Float64, 1}(undef, length(path)-1)
    # dist = Array{Float64, 1}(undef, length(path)-1)
    
    # for i=1:length(path)-1
    #     time[i] = speedmatrix[path[i], path[i+1]]
    #     dist[i] = network.distmx[path[i], path[i+1]]
    # end
    time, dist = pathtimedist(path, speedmatrix, network.distmx)
    if sum(time) == sum(dist) == 0 && length(path) > 0 && source != destination
        return [], [Inf], [Inf]
    end
    return path, time, dist
end

function quickestpath(network::OSMNetwork, source::Tuple{Float64, Float64}, destination::Tuple{Float64, Float64}; warn=true)
    src = network.nodesource[treenearestnode(network, source)]
    dst = network.nodesource[treenearestnode(network, destination)]
    return quickestpath(network, src, dst, warn=warn)
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
    latlons = [get(network.data.nodes, x, 99999) for x in roadnodes]
    # latlons = get.(network.data.nodes, roadnodes, 99999)
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
the matrix actually stores the inverse speed.
"""
function constructspeedmatrix(network::OSMNetwork,
    speeddict::Union{Dict{String, Float64}, Dict{Symbol, Float64}}=SPEEDLIMIT_URBAN)
    access = network.access
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
        if keytype(speeddict) == Symbol
            wayclass = get(ROADCLASSES, waytype, :service)
            speed = get(speeddict, wayclass, 5)
        elseif keytype(speeddict) == String
            speed = get(speeddict, waytype, 5)
        else
            throw("Invalid speed dictionary in constructspeedmatrix")
        end
        for n in 2:length(way)
            push!(edgestart, way[n-1])
            push!(edgeend, way[n])
            push!(edgespeed, speed)
        end
    end
    # return edgestart, edgeend, edgespeed
    es = get.(Ref(network.nodesource), edgestart, 0)
    ee = get.(Ref(network.nodesource), edgeend, 0)
    println(size(es),size(ee),size(edgespeed))
    println(maximum([ee;es]))
    # println(findall(ee.>1317))
    speedmx = SparseArrays.sparse([es;ee], [ee;es], 1.0./[edgespeed;edgespeed], maximum([es;ee]), maximum([es;ee]), max)
end
