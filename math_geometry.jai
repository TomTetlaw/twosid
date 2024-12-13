
IsTriangleCounterClockwise :: (a: float3, b: float3, c: float3) -> bool {
    e1 := b - a;
    e2 := c - a;
    n := Normalize(Cross(e1, e2));
    return Dot(n, .{1, 0, 0}) > 0;
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
}

ray_triangle_hit :: struct {
    Intersected: bool;
    T: float;
    Point: float3;
}

RayTriangleIntersection :: (Ray: ray, Triangle: triangle) -> ray_triangle_hit {
    Epsilon := 0.000001;
    
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
        Point := Ray.Origin + Ray.Direction * T;
        return .{true, T, Point};
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
            }
        }
    }
    
    return ClosestHit;
}