function plotmap(osmdata::OSMData, access::Dict{String,Symbol}=ACCESS["motorcar"])
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
        #add points to array
        if haskey(latPaths, waytype)
            push!(latPaths[waytype], lat)
            push!(lonPaths[waytype], lon)
        else
            error("Couldn't find key $waytype in the paths")
        end
    end
    # x = rand(5,5)
    # y = rand(5,5)
    Plots.plot()
    for pathtype in approvedpaths
        Plots.plot!(lonPaths[pathtype], latPaths[pathtype], label="", color=MAP_COLORS[pathtype])
    end
    Plots.gui()
    
end