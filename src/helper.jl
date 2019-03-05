

function nodelatlon(data::OSMData, node::Int)
    return(data.nodes.lat[data.nodes.id .==node][1], data.nodes.lon[data.nodes.id .==node][1])
end

function getways(data::OSMData, key::String, value::String)
    tags(w::Int) = get(data.tags, w, Dict{String,String}())
    isfeature(w::Int) = get(tags(w), key, "") == value
    wayids = filter(isfeature, collect(keys(data.tags)))
end
