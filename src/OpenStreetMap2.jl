
__precompile__()

module OpenStreetMap2
    import ProtoBuf,
    EzXML,
    CodecZlib,
    HTTP,
    LightGraphs,
    DataStructures,
    Compat,
    SparseArrays,
    LinearAlgebra,
    NearestNeighbors,
    RecipesBase,
    Statistics

    Plots.gr()
    include("types.jl")
    include("io.jl")
    include("access.jl")
    include("network.jl")
    include("routing.jl")
    include("viewer.jl")
    include("helper.jl")

end
