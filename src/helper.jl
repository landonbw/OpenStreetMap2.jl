

function nodelatlon(data::OSMData, node::Int)
    return(data.nodes.lat[data.nodes.id .==node][1], data.nodes.lon[data.nodes.id .==node][1])
end