using OpenStreetMap2; const OSM = OpenStreetMap2
using Base.Test

@testset "Testing Maldives OSM" begin

    @testset "Working with RawOSMData()" begin
        
        @time maldives_osm = OSM.readpbf("pbf/maldives.osm.pbf")
        
        @testset "Testing HeaderBlock" begin
            header = maldives_osm.header
            @test header.optional_features == []
            @test header.required_features == [
                "OsmSchema-V0.6",
                "DenseNodes"
            ]
            @test header.writingprogram == "osmium/1.5.1"
            @test header.osmosis_replication_timestamp == 1512078182
            @test header.osmosis_replication_base_url == "http://download.geofabrik.de/asia/maldives-updates"
        end

        @testset "Testing PrimitiveBlocks" begin
            primitives = maldives_osm.primitives
            @test length(primitives) == 24
            @test primitives[1].date_granularity == 1000
            @test primitives[1].granularity == 100
            @test primitives[1].lat_offset == 0
            @test primitives[1].lon_offset == 0
            @test length(primitives[1].primitivegroup) == 1
        end

        @testset "Testing PrimitiveGroups" begin
            pg = maldives_osm.primitives[1].primitivegroup[1]
            @test length(pg.nodes) == 0
            @test length(pg.relations) == 0
            @test length(pg.ways) == 0

            @test length(pg.dense.id) == 8000
            @test length(pg.dense.lat) == 8000
            @test length(pg.dense.lon) == 8000

            @test length(pg.dense.denseinfo.uid) == 8000
            @test length(pg.dense.denseinfo.changeset) == 8000
            @test length(pg.dense.denseinfo.version) == 8000
            @test length(pg.dense.denseinfo.timestamp) == 8000
            @test length(pg.dense.denseinfo.user_sid) == 8000
            @test length(pg.dense.keys_vals) == 22678
            @test sum(pg.dense.keys_vals .== 0) == 8000
        end
    end

    @testset "Working with OSMData" begin
        
        @time maldives_osm = OSM.readpbf("pbf/maldives.osm.pbf", OSM.OSMData())
        
        @testset "Testing Nodes" begin    
            @test length(maldives_osm.nodes.id) == length(maldives_osm.nodes.lon)
            @test length(maldives_osm.nodes.lon) == length(maldives_osm.nodes.lat)
            @test [maldives_osm.nodeid[id] for id in maldives_osm.nodes.id] ==
                collect(1:length(maldives_osm.nodes.id))
        end

        @testset "Testing Ways" begin
            @test length(maldives_osm.ways) == 19955
        end

        @testset "Testing Relations" begin
            @test length(maldives_osm.relations) == 841
            @test maldives_osm.relations[7095131] == Dict(
                "role" => ["inner", "outer"],
                "id"   => [19879255, 481850745],
                "type" => [:Way, :Way]
            )
            @test length(maldives_osm.ways[19879255]) == 63
            @test length(maldives_osm.ways[481850745]) == 16
        end

        @testset "Testing Tags" begin
            @test length(maldives_osm.tags) == 39745
            @test maldives_osm.tags[7095131] == Dict(
                "natural" => "reef",
                "type"    => "multipolygon"
            )
        end
    end
end

@testset "Testing Maldives OSH" begin
    @time maldives_osh = OSM.readpbf("pbf/maldives.osh.pbf")
    
    @testset "Testing HeaderBlock" begin
        header = maldives_osh.header
        @test header.optional_features == []
        @test header.required_features == [
            "OsmSchema-V0.6",
            "DenseNodes",
            "HistoricalInformation"
        ]
        @test header.writingprogram == "osmium/1.5.1"
        @test header.osmosis_replication_timestamp == 0
        @test header.osmosis_replication_base_url == ""
    end

    @testset "Testing PrimitiveBlocks" begin
        primitives = maldives_osh.primitives
        @test length(primitives) == 37
        @test primitives[1].date_granularity == 1000
        @test primitives[1].granularity == 100
        @test primitives[1].lat_offset == 0
        @test primitives[1].lon_offset == 0
        @test length(primitives[1].primitivegroup) == 1
    end

    @testset "Testing PrimitiveGroups" begin
        pg = maldives_osh.primitives[1].primitivegroup[1]
        @test length(pg.nodes) == 0
        @test length(pg.relations) == 0
        @test length(pg.ways) == 0

        @test length(pg.dense.id) == 8000
        @test length(pg.dense.lat) == 8000
        @test length(pg.dense.lon) == 8000

        @test length(pg.dense.denseinfo.uid) == 8000
        @test length(pg.dense.denseinfo.changeset) == 8000
        @test length(pg.dense.denseinfo.version) == 8000
        @test length(pg.dense.denseinfo.timestamp) == 8000
        @test length(pg.dense.denseinfo.user_sid) == 8000
        @test length(pg.dense.keys_vals) == 28716
        @test sum(pg.dense.keys_vals .== 0) == 8000
    end
end