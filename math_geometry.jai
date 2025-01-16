
 TriangleCounterClockwise :: (a: float3, b: float3, c: float3) -> bool {
    e1 := b - a;
    e2 := c - a;
    D := Dot(Cross(e1, e2), .{0, 0, 1});
    return D < 0;
}

GetCameraForward :: (Camera: *$T/interface view_parameters) -> float3 {
    return Normalize(Camera.View.Rows[0].xyz);
}

GetRayFromCamera :: (Camera: *$T/interface view_parameters) -> ray {
    Result: ray;
    
    Result.Origin = Camera.Position;
    Result.Direction = GetCameraForward(Camera);
    
    return Result;
}

GetRayForMousePosition :: (ViewParams: view_parameters, Pos: float2) -> ray {
    NDCx := (2.0 * Pos.x) / GWindowSize.x - 1.0;
    NDCy := 1.0 - (2.0 * Pos.y) / GWindowSize.y;
    NDCz := -1.0;
    
    ClipNear := float4.{NDCx, NDCy, -1.0, 1.0};
    ClipFar := float4.{NDCx, NDCy, 1.0, 1.0};
    
    InvProj := InverseMatrix(ViewParams.Proj);
    
    ViewSpaceNear := InvProj * ClipNear;
    ViewSpaceFar := InvProj * ClipFar;
    
    ViewSpaceNear /= xyzw(xyz(ViewSpaceNear.w), 1.0);
    ViewSpaceFar /= xyzw(xyz(ViewSpaceFar.w), 1.0);
    
    InvView := InverseMatrix(ViewParams.View);
    
    WorldSpaceNear := InvView * ViewSpaceNear;
    WorldSpaceFar := InvView * ViewSpaceFar;
    
    WorldSpaceNear /= xyzw(xyz(WorldSpaceNear.w), 1.0);
    WorldSpaceFar /= xyzw(xyz(WorldSpaceFar.w), 1.0);
    
    return .{WorldSpaceNear.xyz, Normalize(WorldSpaceFar.xyz - WorldSpaceNear.xyz)};
}

RayIntersectsBox :: (Box: bounding_box, Ray: ray) -> bool {
    InvDir := xyz(1.0) / Ray.Direction;
    
    T1 := (Box.Min.x - Ray.Origin.x) * InvDir.x;
    T2 := (Box.Max.x - Ray.Origin.x) * InvDir.x;
    
    TMin := Min(T1, T2);
    TMax := Max(T1, T2);
    
    for 0..2 {
        T1 = (Box.Min[it] - Ray.Origin[it]) * InvDir[it];
        T2 = (Box.Max[it] - Ray.Origin[it]) * InvDir[it];
        
        TMin = Max(TMin, Min(T1, T2));
        TMax = Min(TMax, Max(T1, T2));
    }
    
    return TMax > Max(TMin, 0.0);
}

RayIntersectsCylinder :: (Cylinder: cylinder, Ray: ray) -> bool {
    Box: bounding_box;
    
    Box.Min.x = Cylinder.Center.x - Cylinder.Radius;
    Box.Min.y = Cylinder.Center.y - Cylinder.Radius;
    Box.Min.z = Cylinder.Center.z - Cylinder.Height*.5;
    
    Box.Max.x = Cylinder.Center.x + Cylinder.Radius;
    Box.Max.y = Cylinder.Center.y + Cylinder.Radius;
    Box.Max.z = Cylinder.Center.z + Cylinder.Height*.5;
    
    return RayIntersectsBox(Box, Ray);
}

ray_hit :: struct {
    Intersected: bool;
    T := FLOAT32_MAX;
    Point: float3;
}

RayPlaneIntersection :: (Ray: ray, Plane: plane) -> ray_hit {
    Denominator := Dot(Plane.Normal, Ray.Direction);
    
    Epsilon :: 0.000001;
    if Abs(Denominator) < Epsilon return .{Intersected=false};
    
    T := (Plane.D - Dot(Plane.Normal, Ray.Origin)) / Denominator;
    if T < 0.0 return .{Intersected=false};
    
    Point := Ray.Origin + T * Ray.Direction;
    return .{true, T, Point};
}

triangle :: struct {
    P1: float3;
    P2: float3;
    P3: float3;
    
#place P1;
    Points: [3] float3;
}

operator [] :: (Tri: triangle, Index: int) -> float3 {
    return Tri.Points[Index];
}

RayTriangleIntersection :: (Ray: ray, Triangle: triangle) -> ray_hit {
    Epsilon := 0.0000001;
    
    E1 := Triangle.P2 - Triangle.P1;
    E2 := Triangle.P3 - Triangle.P1;
    
    H := Cross(Ray.Direction, E2);
    A := Dot(E1, H);
    if Abs(A) < Epsilon return .{Intersected = false};
    
    F := 1.0 / A;
    S := Ray.Origin - Triangle.P1;
    U := F * Dot(S, H);
    if U < 0.0 || U > 1.0 return .{Intersected = false};
    
    Q := Cross(S, E1);
    V := F * Dot(Ray.Direction, Q);
    if V < 0.0 || U + V > 1.0 return .{Intersected = false};
    
    T := F * Dot(E2, Q);
    if T > Epsilon {
        Point := Ray.Origin + T * Ray.Direction;
        return .{true, T, Point};
    }
    
    return .{Intersected = false};
}

RayMeshIntersection :: (Ray: ray, Mesh: collision_mesh, ToWorld: float4x4) -> ray_hit {
    BestT := FLOAT32_MAX;
    BestHit: ray_hit;
    
    for Mesh.Tris {
        Tri: triangle;
        Tri.P1 = (ToWorld * xyzw(it.P1, 1.0)).xyz;
        Tri.P2 = (ToWorld * xyzw(it.P2, 1.0)).xyz;
        Tri.P3 = (ToWorld * xyzw(it.P3, 1.0)).xyz;
        
        Hit := RayTriangleIntersection(Ray, Tri);
        if Hit.Intersected && Hit.T < BestT {
            BestT = Hit.T;
            BestHit = Hit;
        }
    }
    
    if BestT < FLOAT32_MAX return BestHit;
    return .{Intersected = false};
}

RayMeshIntersection :: (Ray: ray, Mesh: collision_mesh) -> ray_hit {
    BestT := FLOAT32_MAX;
    BestHit: ray_hit;
    
    for Mesh.Tris {
        Hit := RayTriangleIntersection(Ray, it);
        if Hit.Intersected && Hit.T < BestT {
            BestT = Hit.T;
            BestHit = Hit;
        }
    }
    
    if BestT < FLOAT32_MAX return BestHit;
    return .{Intersected = false};
}

surface_hit :: struct {
    Intersected: bool;
    Z := FLOAT32_MAX;
    TriIndex := -1;
}

RaySurfaceIntersection :: (Surface: *surface_collision_mesh, Ray: float2) -> surface_hit {
    BestZ :: 32 * 0;
    Surface.m256Base[BestZ / 32] = PackFloat8(-FLOAT32_MAX);
    
    Zero :: 32 * 1;
    Surface.m256Base[Zero / 32] = PackFloat8(0.0);
    One :: 32 * 2;
    Surface.m256Base[One / 32] = PackFloat8(1.0);
    
    Rx:: 32 * 3;
    Surface.m256Base[Rx / 32] = PackFloat8(Ray.x);
    Ry :: 32 * 4;
    Surface.m256Base[Ry / 32] = PackFloat8(Ray.y);
    
    BestIndex :: 32 * 0;
    Surface.m256BaseI[BestIndex / 32] = PackInt8(-1);
    
    Index :: 32 * 1;
    Surface.m256BaseI[Index / 32] = PackInt8(.[0, 1, 2, 3, 4, 5, 6, 7]);
    
    IndexInc :: 32 * 2;
    Surface.m256BaseI[IndexInc / 32] = PackInt8(8);
    
    m256Base := Surface.m256Base.data;
    m256BaseI := Surface.m256BaseI.data;
    
#asm {
        mov Base:, m256Base;
        mov BaseI:, m256BaseI;
        
        movaps C0:, [Base + Zero];
        movaps C1:, [Base + One];
        
        movaps rx:, [Base + Rx];
        movaps ry:, [Base + Ry];
        
        movaps bz:, [Base + BestZ];
        
        movdqa bi:, [BaseI + BestIndex];
        movdqa i:, [BaseI + Index];
        
        movdqa inc:, [BaseI + IndexInc];
    }
    
    for Surface.Triangles {
        Px := *it.Px;
        Py := *it.Py;
        Pz := *it.Pz;
        
        Ux := *it.Ux;
        Uy := *it.Uy;
        
        Vx := *it.Vx;
        Vy := *it.Vy;
        
        Zu := *it.Zu;
        Zv := *it.Zv;
        
#asm {
            // RX,RY = R - P
            subps RX:, rx, [Px];
            subps RY:, ry, [Py];
            
            // U = Uxy . R
            mulps r1:, RX, [Ux];
            mulps r2:, RY, [Uy];
            addps U:, r1, r2;
            
            // V = Uxy . R
            mulps r3:, RX, [Vx];
            mulps r4:, RY, [Vy];
            addps V:, r3, r4;
            
            // Z = Pz + (U * Zu) + (V * Zv)
            mulps r5:, U, [Zu];
            mulps r6:, V, [Zv];
            addps Z:, r5, r6;
            addps Z, Z, [Pz];
            
            cmpps c1:, U, C0, _CMP_GE_OQ; // U >= 0
            cmpps c2:, V, C0, _CMP_GE_OQ; // V >= 0
            
            addps UV:, U, V;
            cmpps c3:, UV, C1, _CMP_LE_OQ; // U+V <= 1
            
            cmpps c4:, Z, bz, _CMP_GT_OQ; // Z > BestZ
            
            andps c1, c1, c2;
            andps c2, c3, c4;
            andps Mask:, c1, c2;
            
            // Record BestZ
            blendvps bz, bz, Z, Mask;
            
            // Record BestIndex
            pblendvb bi, bi, i, Mask;
            
            // Move indices forward
            paddd i, i, inc;
        }
    }
    
#asm {
        movaps [Base + BestZ], bz;
        movdqa [BaseI + BestIndex], bi;
    }
    
    BestHit: surface_hit;
    BestHit.Z = -FLOAT32_MAX;
    BestHit.TriIndex = -1;
    
    Z := m256Base[BestZ];
    I := m256BaseI[BestIndex];
    
    for 0..7 {
        if I[it] != -1 && Z[it] > BestHit.Z {
            BestHit.Z = Z[it];
            
            // Don't bother with this if we won't care about the hit index
            if Surface.Indices.count > 0 {
                Index := ((I[it] / 8) * 8) + ((I[it] % 8) * 3);
                BestHit.TriIndex = Surface.Indices[Index];
            } else {
                BestHit.TriIndex = 0; // fake value
            }
        }
    }
    
    if BestHit.TriIndex >= 0 {
        BestHit.Intersected = true;
    }
    
    return BestHit;
}

collision_mesh :: struct {
    Tris: [] triangle;
}

CreateCollisionMesh :: (Arena: *arena, Mesh: *mesh) -> collision_mesh {
    TriangleCount := Mesh.NumIndices / 3;
    
    Mark := GetArenaMark(Arena);
    
    for 0..TriangleCount-1 {
        Index1 := Mesh.Indices[it*3 + 0];
        Index2 := Mesh.Indices[it*3 + 1];
        Index3 := Mesh.Indices[it*3 + 2];
        
        P1 := Mesh.Positions[Index1];
        P2 := Mesh.Positions[Index2];
        P3 := Mesh.Positions[Index3];
        
        PushToArena(Arena, triangle.{P1, P2, P3});
    }
    
    Result: collision_mesh;
    Result.Tris = ArenaToView(Arena, triangle, Mark);
    return Result;
}

CreateStaticCollisionMesh :: (Arena: *arena, Mesh: *mesh, ToWorld: float4x4) -> collision_mesh {
    TriangleCount := Mesh.NumIndices / 3;
    
    Mark := GetArenaMark(Arena);
    
    for 0..TriangleCount-1 {
        Index1 := Mesh.Indices[it*3 + 0];
        Index2 := Mesh.Indices[it*3 + 1];
        Index3 := Mesh.Indices[it*3 + 2];
        
        P1 := (ToWorld * xyzw(Mesh.Positions[Index1], 1.0)).xyz;
        P2 := (ToWorld * xyzw(Mesh.Positions[Index2], 1.0)).xyz;
        P3 := (ToWorld * xyzw(Mesh.Positions[Index3], 1.0)).xyz;
        
        PushToArena(Arena, triangle.{P1, P2, P3});
    }
    
    Result: collision_mesh;
    Result.Tris = ArenaToView(Arena, triangle, Mark);
    return Result;
}

surface_triangle_8 :: struct {
    Px, Py, Pz: float8;
    Ux, Uy, Zu: float8;
    Vx, Vy, Zv: float8;
}

surface_collision_mesh :: struct {
    Indices: [] u32;
    Triangles: [] surface_triangle_8;
    m256Base: [] float8;
    m256BaseI: [] int32x8;
}

CreateSurfaceCollisionMesh :: (Arena: *arena, Mesh: *mesh, ToWorld: float4x4) -> surface_collision_mesh {
    TriangleCount := Mesh.NumIndices / 3;
    PackedTriangleCount := ((TriangleCount + 7) & ~7) / 8;
    if PackedTriangleCount == 0 PackedTriangleCount = 1;
    
    Triangles := ArenaAlloc(Arena, surface_triangle_8, PackedTriangleCount, .{Align=32});
    for PackedIndex: 0..PackedTriangleCount-1 {
        TrianglesLeft := TriangleCount - (PackedIndex * 8);
        MaxIndex := Min(TrianglesLeft, 8);
        
        CoordX: [8] float;
        CoordY: [8] float;
        CoordZ: [8] float;
        
        PackedTriangle := *Triangles[PackedIndex];
        
        for T: 0..MaxIndex-1 {
            TriangleIndex := (PackedIndex * 8) + T;
            
            Index0 := Mesh.Indices[TriangleIndex*3 + 0];
            Index1 := Mesh.Indices[TriangleIndex*3 + 1];
            Index2 := Mesh.Indices[TriangleIndex*3 + 2];
            
            P1 := Mesh.Positions[Index0];
            P2 := Mesh.Positions[Index1];
            P3 := Mesh.Positions[Index2];
            
            P1 = (ToWorld * xyzw(P1, 1.0)).xyz;
            P2 = (ToWorld * xyzw(P2, 1.0)).xyz;
            P3 = (ToWorld * xyzw(P3, 1.0)).xyz;
            
            E1 := P2 - P1;
            E2 := P3 - P1;
            N := Cross(E1, E2);
            
            D := E1.x * E2.y - E1.y * E2.x;
            
            Ux := E2.y / D;
            Uy := -E2.x / D;
            
            Vx := -E1.y / D;
            Vy := E1.x / D;
            
            Zu := E1.z;
            Zv := E2.z;
            
            PackedTriangle.Px[T] = P1.x;
            PackedTriangle.Py[T] = P1.y;
            PackedTriangle.Pz[T] = P1.z;
            
            PackedTriangle.Ux[T] = Ux;
            PackedTriangle.Uy[T] = Uy;
            
            PackedTriangle.Vx[T] = Vx;
            PackedTriangle.Vy[T] = Vy;
            
            PackedTriangle.Zu[T] = Zu;
            PackedTriangle.Zv[T] = Zv;
        }
        
        for T: MaxIndex..7 {
            PackedTriangle.Px[T] = 999999.0;
            PackedTriangle.Py[T] = 999999.0;
            PackedTriangle.Pz[T] = 999999.0;
            PackedTriangle.Ux[T] = 999999.0;
            PackedTriangle.Uy[T] = 999999.0;
            PackedTriangle.Vx[T] = 999999.0;
            PackedTriangle.Vy[T] = 999999.0;
            PackedTriangle.Zu[T] = 999999.0;
            PackedTriangle.Zv[T] = 999999.0;
        }
    }
    
    Result: surface_collision_mesh;
    Result.Indices = Mesh.Indices;
    Result.Triangles = Triangles;
    Result.m256Base = ArenaAlloc(Arena, float8, 32, .{Align=32});
    Result.m256BaseI = ArenaAlloc(Arena, int32x8, 32, .{Align=32});
    return Result;
}

CreateSurfaceCollisionMesh :: (Arena: *arena, Triangles: [] triangle) -> surface_collision_mesh {
    TriangleCount := Triangles.count;
    PackedTriangleCount := ((TriangleCount + 7) & ~7) / 8;
    if PackedTriangleCount == 0 PackedTriangleCount = 1;
    
    PackedTriangles := ArenaAlloc(Arena, surface_triangle_8, PackedTriangleCount, .{Align=32});
    for PackedIndex: 0..PackedTriangleCount-1 {
        TrianglesLeft := TriangleCount - (PackedIndex * 8);
        MaxIndex := Min(TrianglesLeft, 8);
        
        CoordX: [8] float;
        CoordY: [8] float;
        CoordZ: [8] float;
        
        PackedTriangle := *PackedTriangles[PackedIndex];
        
        for T: 0..MaxIndex-1 {
            TriangleIndex := (PackedIndex * 8) + T;
            
            P1 := Triangles[TriangleIndex].P1;
            P2 := Triangles[TriangleIndex].P2;
            P3 := Triangles[TriangleIndex].P3;
            
            E1 := P2 - P1;
            E2 := P3 - P1;
            N := Cross(E1, E2);
            
            D := E1.x * E2.y - E1.y * E2.x;
            
            Ux := E2.y / D;
            Uy := -E2.x / D;
            
            Vx := -E1.y / D;
            Vy := E1.x / D;
            
            Zu := E1.z;
            Zv := E2.z;
            
            PackedTriangle.Px[T] = P1.x;
            PackedTriangle.Py[T] = P1.y;
            PackedTriangle.Pz[T] = P1.z;
            
            PackedTriangle.Ux[T] = Ux;
            PackedTriangle.Uy[T] = Uy;
            
            PackedTriangle.Vx[T] = Vx;
            PackedTriangle.Vy[T] = Vy;
            
            PackedTriangle.Zu[T] = Zu;
            PackedTriangle.Zv[T] = Zv;
        }
        
        for T: MaxIndex..7 {
            PackedTriangle.Px[T] = 999999.0;
            PackedTriangle.Py[T] = 999999.0;
            PackedTriangle.Pz[T] = 999999.0;
            PackedTriangle.Ux[T] = 999999.0;
            PackedTriangle.Uy[T] = 999999.0;
            PackedTriangle.Vx[T] = 999999.0;
            PackedTriangle.Vy[T] = 999999.0;
            PackedTriangle.Zu[T] = 999999.0;
            PackedTriangle.Zv[T] = 999999.0;
        }
    }
    
    Result: surface_collision_mesh;
    Result.Indices = .[];
    Result.Triangles = PackedTriangles;
    Result.m256Base = ArenaAlloc(Arena, float8, 5, .{Align=32});
    Result.m256BaseI = ArenaAlloc(Arena, int32x8, 3, .{Align=32});
    return Result;
}

PointIntersectsBox :: (Point: float2, Box: bounding_box_2d) -> bool {
    if Point.x < Box.Min.x return false;
    if Point.y < Box.Min.y return false;
    if Point.x > Box.Max.x return false;
    if Point.y > Box.Max.y return false;
    return true;
}
