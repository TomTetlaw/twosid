
GetGroundHeight :: (Position: float3) -> float {
    Hit := RaySurfaceIntersection(*CollisionMesh, Position.xy);
    return Hit.Z;
}

InitTerrain :: () {
    TerrainMesh = LoadMesh("meshes/terrain.mesh");
    
    TerrainTextures = ArenaPushN(*TerrainArena, *texture, 3);
    TerrainTextures[0] = LoadTexture("textures/terrain_diffuse.png");
    TerrainTextures[1] = LoadTexture("textures/terrain_normal.png");
    TerrainTextures[2] = LoadTexture("textures/unit_rmaoh.png");
    
    TerrainTransform = IdentityMatrix();
    
    CollisionMesh = CreateSurfaceCollisionMesh(*TerrainArena, TerrainMesh, TerrainTransform);
}

DrawTerrain :: () {
    Command: draw_command_mesh;
    //Command.Flags = .NO_CAST_SHADOWS;
    Command.Mesh = TerrainMesh;
    Command.Textures = TerrainTextures;
    Command.Instance.Transform = TerrainTransform;
    Command.Instance.DiffuseColour = .{1, 1, 1, 1};
    Command.Instance.MaterialParams = .{1, 1, 1, 1};
    AddDrawCommand(*Command);
}

#scope_file

CollisionMesh: surface_collision_mesh;
TerrainMesh: *mesh;
TerrainTransform: float4x4;
TerrainTextures: [] *texture;
TerrainArena: arena;