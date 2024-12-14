
operator [] :: (v: float2, Index: int) -> float {
    return v.Components[Index];
}

operator [] :: (v: float3, Index: int) -> float {
    return v.Components[Index];
}

operator [] :: (v: float4, Index: int) -> float {
    return v.Components[Index];
}

operator [] :: (v: quat, Index: int) -> float {
    return v.Components[Index];
}

operator + :: (a: float2, b: float2) -> float2 {
    return .{
        a.x + b.x,
        a.y + b.y
    };
}

operator - :: (a: float2, b: float2) -> float2 {
    return .{
        a.x - b.x,
        a.y - b.y
    };
}

operator - :: (v: float2) -> float2 {
    return .{
        -v.x,
        -v.y
    };
}

operator * :: (a: float2, b: float2) -> float2 {
    return .{
        a.x * b.x,
        a.y * b.y
    };
}

operator / :: (a: float2, b: float2) -> float2 {
    return .{
        a.x / b.x,
        a.y / b.y
    };
}

operator * :: (a: float2, f: float) -> float2 #symmetric {
    return .{
        a.x * f,
        a.y * f
    };
}

operator / :: (a: float2, f: float) -> float2 {
    return .{
        a.x / f,
        a.y / f
    };
}

operator + :: (a: float3, b: float3) -> float3 {
    return .{
        a.x + b.x,
        a.y + b.y,
        a.z + b.z
    };
}

operator - :: (a: float3, b: float3) -> float3 {
    return .{
        a.x - b.x,
        a.y - b.y,
        a.z - b.z
    };
}

operator - :: (v: float3) -> float3 {
    return .{
        -v.x,
        -v.y,
        -v.z
    };
}

operator * :: (a: float3, b: float3) -> float3 {
    return .{
        a.x * b.x,
        a.y * b.y,
        a.z * b.z
    };
}

operator / :: (a: float3, b: float3) -> float3 {
    return .{
        a.x / b.x,
        a.y / b.y,
        a.z / b.z
    };
}

operator * :: (a: float3, f: float) -> float3 #symmetric {
    return .{
        a.x * f,
        a.y * f,
        a.z * f
    };
}

operator / :: (a: float3, f: float) -> float3 {
    return .{
        a.x / f,
        a.y / f,
        a.z / f
    };
}

operator + :: (a: float4, b: float4) -> float4 {
    return .{
        a.x + b.x,
        a.y + b.y,
        a.z + b.z,
        a.w + b.w
    };
}

operator - :: (a: float4, b: float4) -> float4 {
    return .{
        a.x - b.x,
        a.y - b.y,
        a.z - b.z,
        a.w - b.w
    };
}

operator - :: (v: float4) -> float4 {
    return .{
        -v.x,
        -v.y,
        -v.z,
        -v.w
    };
}

operator * :: (a: float4, b: float4) -> float4 {
    return .{
        a.x * b.x,
        a.y * b.y,
        a.z * b.z,
        a.w * b.w
    };
}

operator / :: (a: float4, b: float4) -> float4 {
    return .{
        a.x / b.x,
        a.y / b.y,
        a.z / b.z,
        a.w / b.w
    };
}

operator * :: (a: float4, f: float) -> float4 #symmetric {
    return .{
        a.x * f,
        a.y * f,
        a.z * f,
        a.w * f
    };
}

operator / :: (a: float4, f: float) -> float4 {
    return .{
        a.x / f,
        a.y / f,
        a.z / f,
        a.w / f
    };
}

operator + :: (a: quat, b: quat) -> quat {
    return .{
        a.x + b.x, 
        a.y + b.y, 
        a.z + b.z, 
        a.w + b.w
    };
}

operator * :: (a: quat, b: quat) -> quat {
    v  := a.xyz;
    av := b.xyz;
    
    r: quat;
    r.w = a.w * b.w - Dot(v, av);
    
    rv := Cross(v, av);
    
    av *= a.w;
    v  *= b.w;
    
    rv = rv + av + v;
    
    r.x = rv.x;
    r.y = rv.y;
    r.z = rv.z;
    
    return r;
}

operator * :: (q: quat, f: float) -> quat #symmetric {
    return .{
        q.x * f, 
        q.y * f, 
        q.z * f, 
        q.w * f
    };
}

operator - :: (a: quat, b: quat) -> quat {
    return .{
        a.x - b.x, 
        a.y - b.y, 
        a.z - b.z, 
        a.w - b.w
    };
}

operator - :: (q: quat) -> quat {
    return .{
        -q.x, 
        -q.y, 
        -q.z, 
        -q.w
    };
}