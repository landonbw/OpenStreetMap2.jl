struct OSMPaths
    latpaths::Dict{String, Array{Array{Float64,1},1}}
    lonpaths::Dict{String, Array{Array{Float64,1},1}}
    pathtypes::Array{String, 1}
end

function osmways(osmdata::OSMData, access::Dict{String,Symbol}=ACCESS["motorcar"])
    # find all the paths that the given access type can use
    tags(w::Int) = get(osmdata.tags, w, Dict{String,String}())
    lookup(tags::Dict{String,String}, k::String) = get(tags, k, "")
    hasaccess(w::Int) = get(access, lookup(tags(w),"highway"), :no) != :no
    ishighway(w::Int) = haskey(tags(w), "highway")
    wayids = filter(hasaccess, filter(ishighway, collect(keys(osmdata.ways))))

    pathtypes = collect(keys(access))
    noaccess = get.(Ref(access), collect(keys(access)), :no).==:no
    approvedpaths = pathtypes[.!noaccess]

    numnodes = length(osmdata.nodes.id)
    nodeid = Dict(zip(osmdata.nodes.id, 1:numnodes))
    # store each type of path in an array that we can pass to the plot command
    latPaths = Dict{String, Array{Array{Float64, 1},1}}()
    lonPaths = Dict{String, Array{Array{Float64, 1},1}}()
    for pathtype in approvedpaths
        latPaths[pathtype] = Array{Float64, 1}()
        lonPaths[pathtype] = Array{Float64, 1}()
    end
    for wayid in wayids
        #get way points
        lat=[]
        lon=[]
        way = osmdata.ways[wayid]
        for ii in 1:length(osmdata.ways[wayid])
            if haskey(nodeid, way[ii])
                push!(lat, osmdata.nodes.lat[nodeid[way[ii]]])
                push!(lon, osmdata.nodes.lon[nodeid[way[ii]]])
            else
                println("couldn't find node $(way[ii])")
            end
        end
        #determine path type
        waytype = lookup(tags(wayid), "highway")
        #ignore things if it is a parking lot
        #add points to array
        if haskey(latPaths, waytype)
            push!(latPaths[waytype], lat)
            push!(lonPaths[waytype], lon)
        else
            error("Couldn't find key $waytype in the paths")
        end
    end
    return OSMPaths(latPaths, lonPaths, approvedpaths)
end

function plotmap(waypoints::OSMPaths)
    latpaths = waypoints.latpaths
    lonpaths = waypoints.lonpaths
    p = Plots.plot()
    for pathtype in waypoints.pathtypes
        nlines = size(lonpaths[pathtype], 1)
        if nlines == 0
            continue
        end

        # println(lonPaths[pathtype],"\n\n\n",size(latPaths[pathtype]), latPaths[pathtype])
        # println("ahhh")
        Plots.plot!(lonpaths[pathtype][1], latpaths[pathtype][1], label=pathtype, color=MAP_COLORS[pathtype])
        Plots.plot!(lonpaths[pathtype][2:end], latpaths[pathtype][2:end], label="", color=MAP_COLORS[pathtype])
    end
    Plots.gui()
    return p
end

function plotmap(osmdata::OSMData, access::Dict{String,Symbol}=ACCESS["motorcar"])
    ways = osmways(osmdata, access)
    plotmap(ways)
end



function plotfeature(osmdata::OSMData, key::String, value::String, baseplot::Plots.Plot=Plots.plot(); kwargs...)
    tags(w::Int) = get(osmdata.tags, w, Dict{String,String}())
    isfeature(w::Int) = get(tags(w), key, "") == value
    wayids = filter(isfeature, collect(keys(osmdata.tags)))

    numnodes = length(osmdata.nodes.id)
    nodeid = Dict(zip(osmdata.nodes.id, 1:numnodes))

    lats = Array{Array{Float64, 1},1}()
    lons = Array{Array{Float64, 1},1}()
    for wayid in wayids
        lat = Array{Float64,1}()
        lon = Array{Float64,1}()
        # println("looking for $wayid")
        way = get(osmdata.ways, wayid, Array{Float64,1}(undef,1))
        # way = osmdata.ways[wayid]
        for ii in 1:length(way)
            if haskey(nodeid, way[ii])
                push!(lat, osmdata.nodes.lat[nodeid[way[ii]]])
                push!(lon, osmdata.nodes.lon[nodeid[way[ii]]])
            else
                # println("couldn't find node $(way[ii])")
            end
        end
        push!(lats, lat)
        push!(lons, lon)
    end
    p = Plots.plot!(baseplot, lons, lats; kwargs...)
end