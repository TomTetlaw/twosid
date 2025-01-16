
GetGroundHeight :: (Position: float3) -> float {
    Triangles := GetRelevantTrianglesForRay(*TerrainBVH, .{xyz(Position.xy, 1000.0), .{0, 0, -1}});
    if TerrainDebug print("Relevant tris: % (% packed)\n", Triangles.count, Triangles.count/8);
    
    Mesh := CreateSurfaceCollisionMesh(*FrameArena, Triangles);
    Hit := RaySurfaceIntersection(*Mesh, Position.xy);
    return Hit.Z;
}

GetGroundPositionAlongRay :: (Ray: ray) -> float3, bool {
    Triangles := GetRelevantTrianglesForRay(*TerrainBVH, Ray);
    
    BestT := FLOAT32_MAX;
    BestPoint: float3;
    for Triangles {
        Hit := RayTriangleIntersection(Ray, it);
        if Hit.Intersected && Hit.T < BestT {
            BestT = Hit.T;
            BestPoint = Hit.Point;
        }
    }
    
    return BestPoint, BestT != FLOAT32_MAX;
}

InitTerrain :: () {
    TerrainTransform = TranslationMatrix(.{0, 0, 0});
    
    TerrainMesh = LoadMesh("meshes/terrain.mesh");
    
    CollisionMesh = CreateStaticCollisionMesh(*TerrainArena, TerrainMesh, TerrainTransform);
    TerrainBVH = BuildBVH(*TerrainArena, CollisionMesh.Tris);
    
    TerrainTextures = ArenaAlloc(*TerrainArena, *texture, 3);
    TerrainTextures[0] = LoadTexture("textures/terrain_diffuse.png");
    TerrainTextures[1] = LoadTexture("textures/terrain_normal.png");
    TerrainTextures[2] = LoadTexture("textures/unit_rmaoh.png");
}

DrawTerrain :: () {
    if !TerrainDebug DrawOpaqueMesh(TerrainTransform, TerrainMesh, TerrainTextures);
    
    if KeyPressed(.SDL_SCANCODE_F3) {
        TerrainDebug = !TerrainDebug;
    }
    
    if TerrainDebug {
        DebugDrawMesh(TerrainMesh, TerrainTransform);
        DrawBVH(*TerrainBVH);
    }
}

#scope_file

TerrainMesh: *mesh;
CollisionMesh: collision_mesh;
TerrainBVH: bvh;

TerrainDebug := false;

TerrainTransform: float4x4;
TerrainTextures: [] *texture;

TerrainArena: arena;

bvh_node :: struct {
    Bounds: bounding_box;
    LeftOrFirstTri: s32;
    TriCount: s32;
    ColliderIndex: s32;
}

bvh :: struct {
    Nodes: [] bvh_node;
    TriIndex: [] s32;
    Triangles: [] triangle;
    NodesUsed := 0;
}

BuildBVH :: (Arena: *arena, Triangles: [] triangle) -> bvh {
    BVH: bvh;
    
    BVH.Nodes = ArenaAlloc(Arena, bvh_node, Triangles.count * 2 - 1);
    BVH.Triangles = Triangles;
    BVH.TriIndex = ArenaAlloc(Arena, s32, Triangles.count);
    for 0..Triangles.count-1 BVH.TriIndex[it] = xx it;
    
    BVH.Nodes[0].LeftOrFirstTri = 0;
    BVH.Nodes[0].TriCount = xx Triangles.count;
    
    UpdateBounds(*BVH, 0);
    
    Subdivide(*BVH, 0);
    
    BVH.Nodes.count = BVH.NodesUsed;
    
    return BVH;
}

Subdivide :: (BVH: *bvh, NodeIndex: int, Depth := 0) {
    Node := *BVH.Nodes[NodeIndex];
    
    if Node.TriCount <= 2 return;
    
    Mid := (Node.Bounds.Min + Node.Bounds.Max) * .5;
    Axis := Depth % 2;
    SplitPos := Mid[Axis];
    
    I := Node.LeftOrFirstTri;
    J := I + Node.TriCount - 1;
    while I <= J {
        Tri := BVH.Triangles[BVH.TriIndex[I]];
        Centroid := (Tri.P1[Axis] + Tri.P2[Axis] + Tri.P3[Axis]) / 3.0;
        
        if Centroid < SplitPos {
            I += 1;
        } else {
            BVH.TriIndex[I], BVH.TriIndex[J] = BVH.TriIndex[J], BVH.TriIndex[I];
            J -= 1;
        }
    }
    
    LeftCount := I - Node.LeftOrFirstTri;
    
    if LeftCount == 0 || LeftCount == Node.TriCount {
        return;
    }
    
    RightCount := Node.TriCount - LeftCount;
    LeftIndex := BVH.NodesUsed + 1;
    RightIndex := BVH.NodesUsed + 2;
    BVH.NodesUsed += 2;
    
    LeftNode := *BVH.Nodes[LeftIndex];
    LeftNode.LeftOrFirstTri = Node.LeftOrFirstTri;
    LeftNode.TriCount = LeftCount;
    
    UpdateBounds(BVH, LeftIndex);
    Subdivide(BVH, LeftIndex, Depth + 1);
    
    RightNode := *BVH.Nodes[RightIndex];
    RightNode.LeftOrFirstTri = I;
    RightNode.TriCount = RightCount;
    
    UpdateBounds(BVH, RightIndex);
    Subdivide(BVH, RightIndex, Depth + 1);
    
    Node.LeftOrFirstTri = xx LeftIndex;
    Node.TriCount = 0;
}

UpdateBounds :: (BVH: *bvh, NodeIndex: int) {
    Node := *BVH.Nodes[NodeIndex];
    
    Box: bounding_box;
    Box.Min = xyz(FLOAT32_MAX);
    Box.Max = xyz(-FLOAT32_MAX);
    
    for 0..Node.TriCount-1 {
        Triangle := BVH.Triangles[BVH.TriIndex[Node.LeftOrFirstTri + it]];
        
        Box.Min.x = Min(Box.Min.x, Min(Min(Triangle.P1.x, Triangle.P2.x), Triangle.P3.x));
        Box.Min.y = Min(Box.Min.y, Min(Min(Triangle.P1.y, Triangle.P2.y), Triangle.P3.y));
        Box.Min.z = Min(Box.Min.z, Min(Min(Triangle.P1.z, Triangle.P2.z), Triangle.P3.z));
        
        Box.Max.x = Max(Box.Max.x, Max(Max(Triangle.P1.x, Triangle.P2.x), Triangle.P3.x));
        Box.Max.y = Max(Box.Max.y, Max(Max(Triangle.P1.y, Triangle.P2.y), Triangle.P3.y));
        Box.Max.z = Max(Box.Max.z, Max(Max(Triangle.P1.z, Triangle.P2.z), Triangle.P3.z));
    }
    
    Node.Bounds = Box;
}

QueryNodes :: (Arena: *arena, BVH: *bvh, NodeIndex: int, Ray: ray)  {
    Assert(NodeIndex >= 0 && NodeIndex < BVH.Nodes.count);
    
    Node := *BVH.Nodes[NodeIndex];
    
    if !RayIntersectsBox(Node.Bounds, Ray) return;
    
    if Node.TriCount == 0 {
        QueryNodes(Arena, BVH, Node.LeftOrFirstTri, Ray);
        QueryNodes(Arena, BVH, Node.LeftOrFirstTri + 1, Ray);
    } else {
        for 0..Node.TriCount-1 {
            Tri := BVH.Triangles[BVH.TriIndex[Node.LeftOrFirstTri + it]];
            PushToArena(Arena, Tri);
        }
    }
}

QueryBVH :: (Arena: *arena, BVH: *bvh, Ray: ray) {
    QueryNodes(Arena, BVH, 0, Ray);
}

DrawBVH :: (BVH: *bvh) {
    for BVH.Nodes {
        DebugDrawBoundingBox(it.Bounds);
    }
}

GetRelevantTrianglesForRay :: (BVH: *bvh, Ray: ray) -> [] triangle {
    Mark := GetArenaMark(*FrameArena);
    QueryBVH(*FrameArena, BVH, Ray);
    Triangles := ArenaToView(*FrameArena, triangle, Mark);
    
    return Triangles;
}