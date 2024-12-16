
GetGroundHeight :: (Position: float3) -> float {
    Ray := ray.{xyz(Position.xy, 100.0), .{0, 0, -1}};
    Hit := RayMeshIntersection(TerrainMesh, TerrainTransform, Ray);
    if Hit.Intersected return Hit.Point.z;
    return 0.0;
}

InitTerrain :: () {
    TerrainMesh = LoadMesh("meshes/terrain.mesh");
    ArrayAdd(*TerrainTextures, LoadTexture("textures/grass_diffuse.png"));
    ArrayAdd(*TerrainTextures, LoadTexture("textures/grass_normal.png"));
    ArrayAdd(*TerrainTextures, LoadTexture("textures/grass_rmaoh.png"));
    
    TerrainTransform = TranslationMatrix(.{0, 0, -6});
}

DrawTerrain :: () {
    Command: draw_command_mesh;
    Command.Flags = 0;
    Command.Mesh = TerrainMesh;
    Command.Textures = TerrainTextures;
    Command.Instance.Transform = TerrainTransform;
    Command.Instance.DiffuseColour = .{1, 1, 1, 1};
    Command.Instance.MaterialParams = .{1, 1, 1, 25};
    AddDrawCommand(*Command);
}

#scope_file

TerrainMesh: *mesh;
TerrainTransform: float4x4;
TerrainTextures: arena_array(*texture);