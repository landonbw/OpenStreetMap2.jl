

function nodelatlon(data::OSMData, node::Int)
    return(data.nodes.lat[data.nodes.id .==node][1], data.nodes.lon[data.nodes.id .==node][1])
end

function getways(data::OSMData, key::String, value::String)
    tags(w::Int) = get(data.tags, w, Dict{String,String}())
    isfeature(w::Int) = get(tags(w), key, "") == value
    wayids = filter(isfeature, collect(keys(data.tags)))
end

function wayidtopoints(osmdata::OSMData, wayid)
    lat = Array{Float64, 1}()
    lon = Array{Float64, 1}()
    nodeids = get(osmdata.ways, wayid, [wayid])
    for node in nodeids
        if haskey(osmdata.nodes, node)
            nodelat, nodelon = osmdata.nodes[node]
            push!(lat, nodelat)
            push!(lon, nodelon)
        end
    end
    lat, lon
end

function collectpoints(osmdata::OSMData, key::String, value::String)
    wayids = findways(osmdata, key, value)
    lats = Array{Float64, 1}()
    lons = Array{Float64, 1}()
    for way in wayids
        lat, lon = wayidtopoints(osmdata, way)
        for (t,n) in zip(lat, lon)
            push!(lats, t)
            push!(lons, n)
        end
    end
    lats, lons
end