

function nodelatlon(data::OSMData, node::Int)
    return(data.nodes.lat[data.nodes.id .==node][1], data.nodes.lon[data.nodes.id .==node][1])
end

function getways(data::OSMData, key::String, value::String)
    tags(w::Int) = get(data.tags, w, Dict{String,String}())
    isfeature(w::Int) = get(tags(w), key, "") == value
    wayids = filter(isfeature, collect(keys(data.tags)))
end

function wayidtopoints(osmdata::OSMData, wayid::Int)
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

function getwaypoints(osmdata::OSMData, key::String, value::String)
    ways = getways(osmdata, key, value)
    points = [wayidtopoints(osmdata, way) for way in ways]
    points2 = Array{Array{Float64, 2}, 1}()
    for (lat, lon) in points
        push!(points2, hcat(lat, lon))
    end
    return points2
    # return [collect(zip(wayidtopoints(osmdata, way))) for way in getways(osmdata, key, value)]
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

shoelacearea(x, y) =
    abs(sum(i * j for (i, j) in zip(x, append!(y[2:end], y[1]))) -
        sum(i * j for (i, j) in zip(append!(x[2:end], x[1]), y))) / 2

"""get points for a given key, value pair.  Returns an array of [lat lon size] 
where size is area of the polygon and lat lon is the average area of the points
for a given way.  If the way has less than 3 points the area is zero"""
function getdestinations(osmdata::OSMData, key::String, value::String)
    pointset = getwaypoints(osmdata, key, value)
    ret = Array{Float64, 2}(undef, 0, 3)
    for set in pointset
        latlon = Statistics.mean(set, dims=1)
        area = shoelacearea(set[:,1], set[:,2])
        ret = vcat(ret, [latlon[1] latlon[2] area])
    end
    return ret
end