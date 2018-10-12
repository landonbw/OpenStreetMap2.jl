struct OSMNetwork
    g::LightGraphs.DiGraph
    data::OSMData
    distmx::SparseArrays.SparseMatrixCSC{Float64, Int}
    nodeid::Dict{Int,Int} # osm_id -> node_id
    nodesource::Dict{Int, Int} # node_id -> osm_id
    connectednodes::Vector{Int}
    wayids::Vector{Int} # [osm_id, ... osm_id]
    nntree::NearestNeighbors.KDTree
    # edgeid::Dict{Tuple{Int,Int},Int}
end

function osmnetwork(osmdata::OSMData, access::Dict{String,Symbol}=ACCESS["all"])
    tags(w::Int) = get(osmdata.tags, w, Dict{String,String}())
    lookup(tags::Dict{String,String}, k::String) = get(tags, k, "")
    hasaccess(w::Int) = get(access, lookup(tags(w),"highway"), :no) != :no
    ishighway(w::Int) = haskey(tags(w), "highway")
    isreverse(w::Int) = lookup(tags(w),"oneway") == "-1"
    function isoneway(w::Int)
        v = lookup(tags(w),"oneway")
        if v == "false" || v == "no" || v == "0"
            return false
        elseif v == "-1" || v == "true" || v == "yes" || v == "1"
            return true
        end
        highway = lookup(tags(w),"highway")
        junction = lookup(tags(w),"junction")
        return (highway == "motorway" ||
                highway == "motorway_link" ||
                junction == "roundabout")
    end
    "distance between the two points in kilometres"
    function distance(n1::Int, n2::Int)
        toradians(degree::Float64) = degree * π / 180.0
        (lat1, lon1) = osmdata.nodes[n1]
        (lat2, lon2) = osmdata.nodes[n2]
        dlat = toradians(lat2 - lat1); dlon = toradians(lon2 - lon1)
        a = sin(dlat/2)^2+sin(dlon/2)^2*cos(toradians(lat1))*cos(toradians(lat2))
        2.0 * atan(sqrt(a), sqrt(1-a)) * 6373.0
    end
    
    wayids = filter(hasaccess, filter(ishighway, collect(keys(osmdata.ways))))
    numnodes = length(osmdata.nodes)

    edgeset = Set{Tuple{Int,Int}}()
    nodeset = Set{Int}()
    latlon = Set{Array{Float64, 1}}()
    for w in wayids
        way = osmdata.ways[w]
        rev, nrev = isreverse(w), !isreverse(w)
        for n in 2:length(osmdata.ways[w])
            n0 = way[n-1] # map osm_id -> node_id
            n1 = way[n]
            startnode = n0*nrev + n1*rev # reverse the direction if need be
            endnode = n0*rev + n1*nrev

            push!(nodeset, n0); push!(nodeset, n1)
            push!(edgeset, (startnode, endnode))
            push!(latlon, [osmdata.nodes[n0][1], osmdata.nodes[n0][2]])
            push!(latlon, [osmdata.nodes[n1][1], osmdata.nodes[n1][2]])
            isoneway(w) || push!(edgeset, (endnode, startnode))
        end
    end
    connectednodes = collect(nodeset)
    edges = reinterpret(Int,collect(edgeset))
    roadnodes = unique(edges)
    I = edges[1:2:end] # collect all start nodes
    J = edges[2:2:end] # collect all end nodes
    # [println(i) for i in I]
    Iids = [findfirst(!iszero, roadnodes.==node) for node in I]
    Jids = [findfirst(!iszero, roadnodes.==node) for node in J]
    # distmx = SparseArrays.sparse(I,J,[distance(i,j) for (i,j) in zip(I,J)],numnodes,numnodes)
    distmx = SparseArrays.sparse(Iids, Jids, [distance(i,j) for (i,j) in zip(I,J)], length(roadnodes), length(roadnodes))
    mapgraphtoosmid = Dict(zip(1:length(roadnodes), roadnodes))
    maposmidtograph = Dict(zip(roadnodes, 1:length(roadnodes)))
    latlonarray = Array{Float64, 2}(undef, 2, length(roadnodes))
    for i in 1:length(roadnodes)
        (lat, lon) = osmdata.nodes[roadnodes[i]]
        latlonarray[1, i] = lat
        latlonarray[2, i] = lon
    end
    tree = NearestNeighbors.KDTree(latlonarray; leafsize=30000)

    OSMNetwork(LightGraphs.SimpleDiGraph(distmx), osmdata, distmx, mapgraphtoosmid, 
                maposmidtograph, roadnodes, wayids, tree)
end


osmnetwork(osmdata::OSMData, access::String) = osmnetwork(osmdata, ACCESS[access])
