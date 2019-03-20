using RecipesBase

function findways(osmdata::OSMData, key::String, value::String)
    tags(w::Int) = get(osmdata.tags, w, Dict{String,String}())
    isfeature(w::Int) = get(tags(w), key, "") == value
    wayids = filter(isfeature, collect(keys(osmdata.tags)))
end

@recipe function f(osmdata::OSMData, access::Dict{String, Symbol}=ACCESS["motorcar"])
    hasaccess(ty::String) = !(access[ty] == :no)
    hasaccess(pair::Pair{String, Symbol}) = pair.second != :no
    accessable = filter(hasaccess, access)
    for pathtype in collect(keys(accessable))
        tags(w::Int) = get(osmdata.tags, w, Dict{String,String}())
        isfeature(w::Int) = get(tags(w), "highway", "") == pathtype
        wayids = filter(isfeature, collect(keys(osmdata.tags)))
        numnodes = length(keys(osmdata.nodes))
        for wayid in wayids

            lat, lon = wayidtopoints(osmdata, wayid)
            @series begin
                color := MAP_COLORS[pathtype]
                label := ""
                lon, lat
            end
        end
    end

end

@recipe function f(network::OSMNetwork)
    @series begin
        x := network.data
        y := network.access
    end
end


@userplot drawfeature

@recipe function f(h::drawfeature)
    count = 0
    if length(h.args) != 3
        error("incorrect number of inputs")
    end
    osmdata, key, value = h.args
    wayids = findways(osmdata, key, value)

    numnodes = length(keys(osmdata.nodes))
    cid = rand(1:15)
    # color --> rand(1:15)
    for wayid in wayids
        lat, lon = wayidtopoints(osmdata, wayid)
        @series begin
            if length(lon) > 2
                seriestype --> :shape
            else
                seriestype --> :scatter
            end
            if count < 1
                label --> "$key: $value"
            else
                label := ""
            end
            color --> cid
            lon, lat
        end
        count += 1
    end
end
