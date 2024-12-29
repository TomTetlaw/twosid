
operator [] :: (v: float2, Index: int) -> float {
    return v.Components[Index];
}

operator [] :: (v: float3, Index: int) -> float {
    return v.Components[Index];
}

operator []= :: (v: *float3, Index: int, Value: float) {
    v.Components[Index] = Value;
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

operator + :: (a: float3, b: float) -> float3 {
    return .{
        a.x + b,
        a.y + b,
        a.z + b
    };
}

operator - :: (a: float3, b: float3) -> float3 {
    return .{
        a.x - b.x,
        a.y - b.y,
        a.z - b.z
    };
}

operator - :: (a: float3, b: float) -> float3 {
    return .{
        a.x - b,
        a.y - b,
        a.z - b
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

operator * :: (q: quat, f: float4) -> quat #symmetric {
    return .{
        q.x * f.x, 
        q.y * f.y, 
        q.z * f.z, 
        q.w * f.w
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

operator * :: (a: float2x2, b: float2x2) -> float2x2 {
    Result: float2x2 = ---;
    
    Result._11 = a._11*b._11 + a._12*b._21;
    Result._21 = a._21*b._11 + a._22*b._21;
    
    Result._12 = a._11*b._12 + a._12*b._22;
    Result._22 = a._21*b._12 + a._22*b._22;
    
    return Result;
}

operator * :: (m: float2x2, b: float) -> float2x2 #symmetric {
    Result: float2x2 = ---;
    
    for i: 0..1 for j: 0..1 {
        Result.Coef[i][j] = m.Coef[i][j] * b;
    }
    
    return Result;
}

operator * :: (m: float2x2, b: float2) -> float2 {
    Result: float2;
    
    Result.x = b.x * m._11 + b.y * m._12;
    Result.y = b.x * m._21 + b.y * m._22;
    
    return Result;
}

operator * :: (a: float4x4, b: float4x4) -> float4x4 {
    Result: float4x4 = ---;
    
    Result._11 = a._11*b._11 + a._12*b._21 + a._13*b._31 + a._14*b._41;
    Result._21 = a._21*b._11 + a._22*b._21 + a._23*b._31 + a._24*b._41;
    Result._31 = a._31*b._11 + a._32*b._21 + a._33*b._31 + a._34*b._41;
    Result._41 = a._41*b._11 + a._42*b._21 + a._43*b._31 + a._44*b._41;
    
    Result._12 = a._11*b._12 + a._12*b._22 + a._13*b._32 + a._14*b._42;
    Result._22 = a._21*b._12 + a._22*b._22 + a._23*b._32 + a._24*b._42;
    Result._32 = a._31*b._12 + a._32*b._22 + a._33*b._32 + a._34*b._42;
    Result._42 = a._41*b._12 + a._42*b._22 + a._43*b._32 + a._44*b._42;
    
    Result._13 = a._11*b._13 + a._12*b._23 + a._13*b._33 + a._14*b._43;
    Result._23 = a._21*b._13 + a._22*b._23 + a._23*b._33 + a._24*b._43;
    Result._33 = a._31*b._13 + a._32*b._23 + a._33*b._33 + a._34*b._43;
    Result._43 = a._41*b._13 + a._42*b._23 + a._43*b._33 + a._44*b._43;
    
    Result._14 = a._11*b._14 + a._12*b._24 + a._13*b._34 + a._14*b._44;
    Result._24 = a._21*b._14 + a._22*b._24 + a._23*b._34 + a._24*b._44;
    Result._34 = a._31*b._14 + a._32*b._24 + a._33*b._34 + a._34*b._44;
    Result._44 = a._41*b._14 + a._42*b._24 + a._43*b._34 + a._44*b._44;
    
    return Result;
}

operator * :: (m: float4x4, b: float) -> float4x4 #symmetric {
    Result: float4x4 = ---;
    
    for i: 0..3 for j: 0..3 {
        Result.Coef[i][j] = m.Coef[i][j] * b;
    }
    
    return Result;
}

operator * :: (m: float4x4, b: float4) -> float4 {
    Result: float4;
    
    Result.x = b.x * m._11 + b.y * m._12 + b.z * m._13 + b.w * m._14;
    Result.y = b.x * m._21 + b.y * m._22 + b.z * m._23 + b.w * m._24;
    Result.z = b.x * m._31 + b.y * m._32 + b.z * m._33 + b.w * m._34;
    Result.w = b.x * m._41 + b.y * m._42 + b.z * m._43 + b.w * m._44;
    
    return Result;
}