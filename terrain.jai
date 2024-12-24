
GetGroundHeight :: (Position: float3) -> float {
    Hit := RaySurfaceIntersection(*CollisionMesh, Position.xy);
    return Hit.Z;
}

InitTerrain :: () {
    TerrainMesh = LoadMesh("meshes/terrain.mesh");
    
    TerrainDebugMesh = CreateTerrainSurfaceMesh("terrain_mesh_clipped", TerrainMesh);
    CollisionMesh = CreateSurfaceCollisionMesh(*TerrainArena, TerrainMesh, TerrainTransform);
    
    TerrainTextures = ArenaPushN(*TerrainArena, *texture, 3);
    TerrainTextures[0] = LoadTexture("textures/terrain_diffuse.png");
    TerrainTextures[1] = LoadTexture("textures/terrain_normal.png");
    TerrainTextures[2] = LoadTexture("textures/unit_rmaoh.png");
    
    TerrainTransform = IdentityMatrix();
}

Boxes := bounding_box.[.{
                           .{-10, -10, -10},
                           .{10, 10, 50}
                       },
                       .{
                           .{-20, -20, -10},
                           .{20, 20, 50}
                       },
                       .{
                           .{-30, -30, -10},
                           .{30, 30, 50}
                       },
                       .{
                           .{-40, -40, -10},
                           .{40, 40, 50}
                       },
                       .{
                           .{-50, -50, -10},
                           .{50, 50, 50}
                       }];

DrawTerrain :: () {
    Command: draw_command_mesh;
    //Command.Flags = .NO_CAST_SHADOWS;
    Command.Mesh = TerrainMesh;
    Command.Textures = TerrainTextures;
    Command.Instance.Transform = TerrainTransform;
    Command.Instance.DiffuseColour = .{1, 1, 1, 1};
    Command.Instance.MaterialParams = .{1, 1, 1, 1};
    //AddDrawCommand(*Command);
    
    Command.Flags = .DEBUG;
    Command.Mesh = TerrainDebugMesh;
    Command.Instance.Transform = TranslationMatrix(.{0, 0, 0.1});
    Command.Instance.DiffuseColour = .{1, 1, 1, 1};
    AddDrawCommand(*Command);
    
    //for Boxes DrawBoundingBox(it, .{1, 0, 0, 1});
}

#scope_file

CreateTerrainSurfaceMesh :: (Name: string, Mesh: *mesh) -> *mesh {
    Mark := ArenaPushMark(*WorkingArena);
    
    TriangleCount := Mesh.NumIndices / 3;
    Triangles := ArenaPushN(*WorkingArena, triangle, TriangleCount);
    for 0..Triangles.count-1 {
        P1 := Mesh.Positions[Mesh.Indices[it*3 + 0]];
        P2 := Mesh.Positions[Mesh.Indices[it*3 + 1]];
        P3 := Mesh.Positions[Mesh.Indices[it*3 + 2]];
        Triangles[it] = .{P1, P2, P3};
    }
    
    BVH := BuildBVH(*WorkingArena, Triangles);
    
    ClippedTriangles := PushFixedArena(*WorkingArena, triangle, TriangleCount * 3);
    
    // This is ugly... add all the original triangles 
    // so we don't have to worry about checking which were clipped.
    // Duplicates will get optimised out later.
    for Triangles ArenaPush(ClippedTriangles, it);
    
    for B: Boxes {
        Triangles := QueryBVH(*WorkingArena, *BVH, B);
        
        for T: Triangles {
            Edges := FindClippingEdges(*WorkingArena, T, B);
            Tris := ClipTriangle(*WorkingArena, T, Edges);
            if Tris.count > 0 {
                for Tris ArenaPush(ClippedTriangles, it);
            }
        }
    }
    
    ClippedSurface := CreateMeshFromTriangles(Name, ArenaToView(ClippedTriangles));
    
    ArenaPopMark(*WorkingArena, Mark);
    
    return ClippedSurface;
}

CollisionMesh: surface_collision_mesh;
TerrainMesh: *mesh;
TerrainDebugMesh: *mesh;
TerrainTransform: float4x4;
TerrainTextures: [] *texture;
TerrainArena: arena;