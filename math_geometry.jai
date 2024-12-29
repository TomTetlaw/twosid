
 TriangleCounterClockwise :: (a: float3, b: float3, c: float3) -> bool {
    e1 := b - a;
    e2 := c - a;
    D := Dot(Cross(e1, e2), .{0, 0, 1});
    return D < 0;
}

ray :: struct {
    Origin: float3;
    Direction: float3;
}

GetRayFromCamera :: (Camera: *$T/interface view_parameters) -> ray {
    Result: ray;
    
    Result.Origin = Camera.Position;
    Result.Direction = Normalize(Camera.View.Rows[0].xyz); // @todo: Need to normalize?
    
    return Result;
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

ray_triangle_hit :: struct {
    Intersected: bool;
    T := FLOAT32_MAX;
    Point: float3;
    TriIndex := -1;
}

RayTriangleIntersection :: (Ray: ray, Triangle: triangle) -> ray_triangle_hit {
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
        return .{true, T, Point, 0};
    }
    
    return .{Intersected = false};
}

RayMeshIntersection :: (Mesh: *mesh, WorldTransform: float4x4, Ray: ray) -> ray_triangle_hit {
    ClosestDistance := FLOAT32_MAX;
    ClosestHit: ray_triangle_hit;
    
    TriangleCount := Mesh.Indices.count / 3;
    for 0..TriangleCount-1 {
        Triangle := triangle.{
            (WorldTransform * xyzw(Mesh.Positions[Mesh.Indices[it*3 + 0]], 1.0)).xyz,
            (WorldTransform * xyzw(Mesh.Positions[Mesh.Indices[it*3 + 1]], 1.0)).xyz,
            (WorldTransform * xyzw(Mesh.Positions[Mesh.Indices[it*3 + 2]], 1.0)).xyz
        };
        
        Hit := RayTriangleIntersection(Ray, Triangle);
        if Hit.Intersected {
            if Hit.T < ClosestDistance {
                ClosestDistance = Hit.T;
                ClosestHit = Hit;
                ClosestHit.TriIndex = it;
            }
        }
    }
    
    return ClosestHit;
}

RayMeshIntersection :: (Mesh: *collision_mesh_8, Ray: ray) -> ray_triangle_hit {
    Mark := ArenaPushMark(*FrameArena);
    
    m256Base := cast (*float8) ArenaAlloc(*FrameArena, size_of(float8) * 32, 32);
    m256BaseI := cast (*int32x8) ArenaAlloc(*FrameArena, size_of(int32x8) * 32, 32);
    
    BestT :: 32 * 0;
    m256Base[BestT / 32] = PackFloat8(FLOAT32_MAX);
    
    Epsilon1 :: 32 * 1;
    m256Base[Epsilon1 / 32] = PackFloat8(0.00001);
    
    Epsilon :: 32 * 2;
    m256Base[Epsilon / 32] = PackFloat8(0.0000001);
    
    Zero :: 32 * 4;
    m256Base[Zero / 32] = PackFloat8(0.0);
    One :: 32 * 5;
    m256Base[One / 32] = PackFloat8(1.0);
    
    RayX :: 32 * 6;
    m256Base[RayX / 32] = PackFloat8(Ray.Origin.x);
    RayY :: 32 * 7;
    m256Base[RayY / 32] = PackFloat8(Ray.Origin.y);
    RayZ :: 32 * 8;
    m256Base[RayZ / 32] = PackFloat8(Ray.Origin.z);
    
    DirX :: 32 * 9;
    m256Base[DirX / 32] = PackFloat8(Ray.Direction.x);
    DirY :: 32 * 10;
    m256Base[DirY / 32] = PackFloat8(Ray.Direction.y);
    DirZ :: 32 * 11;
    m256Base[DirZ / 32] = PackFloat8(Ray.Direction.z);
    
    BestIndex :: 32 * 0;
    m256BaseI[BestIndex / 32] = PackInt8(-1);
    
    Index :: 32 * 1;
    m256BaseI[Index / 32] = PackInt8(.[7, 6, 5, 4, 3, 2, 1, 0]);
    
    IndexInc :: 32 * 2;
    m256BaseI[IndexInc / 32] = PackInt8(8);
    
    AbsMask :: 32 * 3;
    m256BaseI[AbsMask / 32] = PackInt8(0x7fffffff);
    
#asm {
        mov Base:, m256Base;
        mov BaseI:, m256BaseI;
    }
    
    for Mesh.Triangles {
        P1x :: 32 * 12;
        m256Base[P1x / 32] = it.P1x;
        P1y :: 32 * 13;
        m256Base[P1y / 32] = it.P1y;
        P1z :: 32 * 14;
        m256Base[P1z / 32] = it.P1z;
        
        Edge1x :: 32 * 15;
        m256Base[Edge1x / 32] = it.E1x;
        Edge1y :: 32 * 16;
        m256Base[Edge1y / 32] = it.E1y;
        Edge1z :: 32 * 17;
        m256Base[Edge1z / 32] = it.E1z;
        
        Edge2x :: 32 * 18;
        m256Base[Edge2x / 32] = it.E2x;
        Edge2y :: 32 * 19;
        m256Base[Edge2y / 32] = it.E2y;
        Edge2z :: 32 * 20;
        m256Base[Edge2z / 32] = it.E2z;
        
#asm {
            r1: vec; r2: vec; r3: vec;
            movaps r1, [Base + DirX];
            movaps r2, [Base + DirY];
            movaps r3, [Base + DirZ];
            
            r4: vec; r5: vec; r6: vec;
            movaps r4, [Base + Edge2x];
            movaps r5, [Base + Edge2y];
            movaps r6, [Base + Edge2z];
            
            Hx: vec; Hy: vec; Hz: vec;
        }
        
        Cross8(r1, r2, r3, r4, r5, r6, Hx, Hy, Hz); // H = D x E2
        
#asm {
            movaps r4, [Base + Edge1x];
            movaps r5, [Base + Edge1y];
            movaps r6, [Base + Edge1z];
            
            r: vec; 
        }
        
        Dot8(r4, r5, r6, Hx, Hy, Hz, r); // A = E1 . H
        
#asm {
            movaps O:, [Base + One];
            divps F:, O, r; // F = 1 / A
            andps r, r, [BaseI + AbsMask];
            cmpps c:, r, [Base + Epsilon1], _CMP_GT_OQ; // Abs(A) > Epsilon
            
            Rx: vec; Ry: vec; Rz: vec;
            movaps Rx, [Base + RayX];
            movaps Ry, [Base + RayY];
            movaps Rz, [Base + RayZ];
            
            // S = R - P
            subps r1, Rx, [Base + P1x];
            subps r2, Ry, [Base + P1y];
            subps r3, Rz, [Base + P1z];
        }
        
        Dot8(r1, r2, r3, Hx, Hy, Hz, r);
        
#asm {
            mulps U:, F, r; // U = F * S . H
            
            // V >= 0
            cmpps c1:, U, [Base + Zero], _CMP_GE_OQ;
            andps c, c, c1;
            
            Qx: vec; Qy: vec; Qz: vec;
            
            movaps r4, [Base + Edge1x];
            movaps r5, [Base + Edge1y];
            movaps r6, [Base + Edge1z];
        }
        
        Cross8(r1, r2, r3, r4, r5, r6, Qx, Qy, Qz); // Q = S x E1
        
#asm {
            movaps r1, [Base + DirX];
            movaps r2, [Base + DirY];
            movaps r3, [Base + DirZ];
        }
        
        Dot8(r1, r2, r3, Qx, Qy, Qz, r);
        
#asm {
            mulps V:, F, r; // V = F * D . Q
            
            // V >= 0
            cmpps c1, V, [Base + Zero], _CMP_GE_OQ;
            andps c, c, c1;
            
            // U+V <= 1.0
            addps s:, U, V;
            cmpps c1, s, [Base + One], _CMP_LE_OQ;
            andps c, c, c1;
            
            movaps r4, [Base + Edge2x];
            movaps r5, [Base + Edge2y];
            movaps r6, [Base + Edge2z];
        }
        
        Dot8(r4, r5, r6, Qx, Qy, Qz, r);
        
#asm {
            mulps T:, F, r; // T = F * D . Q
            
            // T > 1e-6
            cmpps c1, T, [Base + Epsilon], _CMP_GT_OQ;
            andps c, c, c1;
            
            movaps Bt:, [Base + BestT];
            cmpps c1, T, Bt, _CMP_LT_OQ;
            andps c, c, c1;
            
            blendvps Bt, Bt, T, c;
            movaps [Base + BestT], Bt;
            
            movdqa bi:, [BaseI + BestIndex];
            movdqa i:, [BaseI + Index];
            pblendvb bi, bi, i, c;
            movdqa [BaseI + BestIndex], bi;
            
            paddd i, i, [BaseI + IndexInc];
            movdqa [BaseI + Index], i;
        }
    }
    
    BestHit: ray_triangle_hit;
    BestHit.T = FLOAT32_MAX;
    BestHit.TriIndex = -1;
    
    T := m256Base[BestT];
    I := m256BaseI[BestIndex];
    
    for 0..7 {
        if T[it] < BestHit.T {
            BestHit.T = T[it];
            BestHit.TriIndex = I[it];
        }
    }
    
    if BestHit.TriIndex >= 0 {
        BestHit.Intersected = true;
        BestHit.Point = Ray.Origin + BestHit.T * Ray.Direction;
    }
    
    ArenaPopMark(*FrameArena, Mark);
    
    return BestHit;
}

surface_hit :: struct {
    Intersected: bool;
    Z := FLOAT32_MAX;
    TriIndex := -1;
}

RaySurfaceIntersection :: (Surface: *surface_collision_mesh, Ray: float2) -> surface_hit {
    Mark := ArenaPushMark(*FrameArena);
    
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
    
    m256Base := Surface.m256Base;
    m256BaseI := Surface.m256BaseI;
    
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
            // U = Uxy . R
            // V = Uxy . R
            subps RX:, rx, [Px];
            subps RY:, ry, [Py];
            
            mulps r1:, RX, [Ux];
            mulps r2:, RY, [Uy];
            addps U:, r1, r2;
            
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
    BestHit.Z = 0.0;
    BestHit.TriIndex = -1;
    
    Z := m256Base[BestZ];
    I := m256BaseI[BestIndex];
    
    for 0..7 {
        if I[it] != -1 && Z[it] > BestHit.Z {
            BestHit.Z = Z[it];
            
            Index := ((I[it] / 8) * 8) + ((I[it] % 8) * 3);
            
            // Don't bother with this if we won't care about the hit index
            if Surface.Indices.count > 0 {
                BestHit.TriIndex = Surface.Indices[Index];
            } else {
                BestHit.TriIndex = 0; // fake value
            }
        }
    }
    
    if BestHit.TriIndex >= 0 {
        BestHit.Intersected = true;
    }
    
    ArenaPopMark(*FrameArena, Mark);
    
    return BestHit;
}

collision_mesh :: struct {
    Tris: [] triangle;
}

CreateCollisionMesh :: (Arena: *arena, Mesh: *mesh, ToWorld: float4x4) -> collision_mesh {
    TriangleCount := Mesh.NumIndices / 3;
    
    Tris := PushFixedArena(Arena, triangle, TriangleCount);
    
    for 0..TriangleCount-1 {
        Index1 := Mesh.Indices[it*3 + 0];
        Index2 := Mesh.Indices[it*3 + 1];
        Index3 := Mesh.Indices[it*3 + 2];
        
        P1 := (ToWorld * xyzw(Mesh.Positions[Index1], 1.0)).xyz;
        P2 := (ToWorld * xyzw(Mesh.Positions[Index2], 1.0)).xyz;
        P3 := (ToWorld * xyzw(Mesh.Positions[Index3], 1.0)).xyz;
        
        ArenaPush(Tris, .{P1, P2, P3});
    }
    
    Result: collision_mesh;
    Result.Tris = ArenaToView(Tris);
    return Result;
}

triangle_8 :: struct {
    P1x, E1x, E2x: float8;
    P1y, E1y, E2y: float8;
    P1z, E1z, E2z: float8;
}

collision_mesh_8 :: struct {
    Triangles: [] triangle_8;
}

CreatePackedCollisionMesh :: (Arena: *arena, Mesh: *mesh, ToWorld: float4x4) -> collision_mesh_8 {
    TriangleCount := Mesh.NumIndices / 3;
    PackedTriangleCount := ((TriangleCount / 8) + 7) & ~7;
    
    Triangles := ArenaPushN(Arena, triangle_8, PackedTriangleCount, Align=32);
    for PackedIndex: 0..PackedTriangleCount-1 {
        TrianglesLeft := TriangleCount - (PackedIndex * 8);
        MaxIndex := Min(TrianglesLeft, 8);
        
        CoordX: [24] float;
        CoordY: [24] float;
        CoordZ: [24] float;
        for T: 0..MaxIndex-1 {
            TriangleIndex := (PackedIndex * 8) + T;
            
            Index0 := Mesh.Indices[TriangleIndex*3 + 0];
            Index1 := Mesh.Indices[TriangleIndex*3 + 1];
            Index2 := Mesh.Indices[TriangleIndex*3 + 2];
            
            P1 := (ToWorld * xyzw(Mesh.Positions[Index0], 1.0)).xyz;
            P2 := (ToWorld * xyzw(Mesh.Positions[Index1], 1.0)).xyz;
            P3 := (ToWorld * xyzw(Mesh.Positions[Index2], 1.0)).xyz;
            
            E1 := P2 - P1;
            E2 := P3 - P1;
            
            CoordX[T] = P1.x;
            CoordY[T] = P1.y;
            CoordZ[T] = P1.z;
            
            CoordX[T + 8] = E1.x;
            CoordY[T + 8] = E1.y;
            CoordZ[T + 8] = E1.z;
            
            CoordX[T + 16] = E2.x;
            CoordY[T + 16] = E2.y;
            CoordZ[T + 16] = E2.z;
        }
        
        PackedTriangle := *Triangles[PackedIndex];
        
        Copy(*PackedTriangle.P1x, *CoordX[0 ], size_of(float8));
        Copy(*PackedTriangle.P1y, *CoordY[0 ], size_of(float8));
        Copy(*PackedTriangle.P1z, *CoordZ[0 ], size_of(float8));
        
        Copy(*PackedTriangle.E1x, *CoordX[8 ], size_of(float8));
        Copy(*PackedTriangle.E1y, *CoordY[8 ], size_of(float8));
        Copy(*PackedTriangle.E1z, *CoordZ[8 ], size_of(float8));
        
        Copy(*PackedTriangle.E2x, *CoordX[16], size_of(float8));
        Copy(*PackedTriangle.E2y, *CoordY[16], size_of(float8));
        Copy(*PackedTriangle.E2z, *CoordZ[16], size_of(float8));
    }
    
    Result: collision_mesh_8;
    Result.Triangles = Triangles;
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
    m256Base: *float8;
    m256BaseI: *int32x8;
}

CreateSurfaceCollisionMesh :: (Arena: *arena, Mesh: *mesh, ToWorld: float4x4) -> surface_collision_mesh {
    TriangleCount := Mesh.NumIndices / 3;
    PackedTriangleCount := ((TriangleCount + 7) & ~7) / 8;
    if PackedTriangleCount == 0 PackedTriangleCount = 1;
    
    Triangles := ArenaPushN(Arena, surface_triangle_8, PackedTriangleCount, Align=32);
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
    Result.m256Base = cast (*float8) ArenaAlloc(Arena, size_of(float8) * 32, 32);
    Result.m256BaseI = cast (*int32x8) ArenaAlloc(Arena, size_of(int32x8) * 32, 32);
    return Result;
}

CreateTemporarySurfaceCollisionMesh :: (Triangles: [] triangle) -> surface_collision_mesh {
    TriangleCount := Triangles.count;
    PackedTriangleCount := ((TriangleCount + 7) & ~7) / 8;
    if PackedTriangleCount == 0 PackedTriangleCount = 1;
    
    PackedTriangles := ArenaPushN(*FrameArena, surface_triangle_8, PackedTriangleCount, Align=32);
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
    Result.m256Base = cast (*float8) ArenaAlloc(*FrameArena, size_of(float8) * 5, 32);
    Result.m256BaseI = cast (*int32x8) ArenaAlloc(*FrameArena, size_of(int32x8) * 3, 32);
    return Result;
}

bounding_box :: struct {
    Min, Max: float3;
}