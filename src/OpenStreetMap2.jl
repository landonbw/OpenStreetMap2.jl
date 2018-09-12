
__precompile__()

module OpenStreetMap2

    import ProtoBuf, EzXML, CodecZlib, HTTP, LightGraphs, DataStructures, Compat

    include("types.jl")
    include("io.jl")
    include("access.jl")
    include("network.jl")
    include("routing.jl")

end
