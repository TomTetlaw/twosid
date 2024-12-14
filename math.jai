
Deg2Rad :: PI / 180.0;
Rad2Deg :: 180.0 / PI;

Turn2Rad :: 2 * PI;
Rad2Turn :: 1.0 / (2 * PI);

Turn2Deg :: PI;
Deg2Turn :: 1.0 / 360.0;

Lerp :: (a: float, b: float, t: float) -> float {
    return a + (b - a) * t;
}

Abs :: (f: float) -> float {
    if f < 0.0 return f * -1.0;
    return f;
}

Min :: (a: float, b: float) -> float {
    if a < b return a;
    return b;
}

Max :: (a: float, b: float) -> float {
    if a > b return a;
    return b;
}

Saturate :: (f: float) -> float {
    return Max(Min(f, 1.0), 0.0);
}

CosTurns :: (t: float) -> float {
    t -= 0.25 + floor(t + 0.25);
    t *= 16.0 * (abs(t) - 0.5);
    t += 0.225 * t * (abs(t) - 1.0);
    return t;
}

SinTurns :: (t: float) -> float {
    return CosTurns(0.25 - t);
}

float2 :: struct {
    x, y: float;
    
#place x;
    Components: [2] float;
}

float3 :: struct {
    x, y, z: float;
    
#place x;
    Components: [3] float;
    
#place x;
    xy: float2;
}

float4 :: struct {
    x, y, z, w: float;
    
#place x;
    Components: [4] float;
    
#place x;
    xy: float2;
    
#place x;
    xyz: float3;
}

quat :: struct {
    x, y, z: float;
    w := 1.0;
    
#place x;
    Components: [4] float;
    
#place x;
    xyz: float3 = ---;
};

Dot :: (a: float2, b: float2) -> float {
    return a.x*b.x + a.y*b.y;
}

Dot :: (a: float3, b: float3) -> float {
    return a.x*b.x + a.y*b.y + a.z*b.z;
}

Dot :: (a: quat, b: quat) -> float {
    return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w;
}

Length :: (v: float2) -> float {
    return sqrt(v.x*v.x + v.y*v.y);
}

Length :: (v: float3) -> float {
    return sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
}

LengthSquared :: (v: float2) -> float {
    return v.x*v.x + v.y*v.y;
}

LengthSquared :: (v: float3) -> float {
    return v.x*v.x + v.y*v.y + v.z*v.z;
}

Normalize :: (v: float2) -> float2 {
    L := Length(v);
    if L == 0.0 return .{1.0, 0.0};
    
    iL := 1.0 / L;
    return v * iL;
}

Normalize :: (v: float3) -> float3 {
    L := Length(v);
    if L == 0.0 return .{1.0, 0.0, 0.0};
    
    iL := 1.0 / L;
    return v * iL;
}

Cross :: (a: float3, b: float3) -> float3 {
    return float3.{
        a.y*b.z - a.z*b.y,
        a.z*b.x - a.x*b.z,
        a.x*b.y - a.y*b.x
    };
}

Distance :: (a: float2, b: float2) -> float {
    Delta := b - a;
    return Length(Delta);
}

Distance :: (a: float3, b: float3) -> float {
    Delta := b - a;
    return Length(Delta);
}

DistanceSquared :: (a: float2, b: float2) -> float {
    Delta := b - a;
    return LengthSquared(Delta);
}

DistanceSquared :: (a: float3, b: float3) -> float {
    Delta := b - a;
    return LengthSquared(Delta);
}

Lerp :: (a: float2, b: float2, t: float) -> float2 {
    return .{
        Lerp(a.x, b.x, t),
        Lerp(a.y, b.y, t)
    };
}

Lerp :: (a: float3, b: float3, t: float) -> float3 {
    return .{
        Lerp(a.x, b.x, t), 
        Lerp(a.y, b.y, t), 
        Lerp(a.z, b.z, t)
    };
}

Abs :: (v: float2) -> float2 {
    return float2.{
        Abs(v.x),
        Abs(v.y)
    };
}

Abs :: (v: float3) -> float3 {
    return float3.{
        Abs(v.x),
        Abs(v.y),
        Abs(v.z)
    };
}

Min :: (a: float2, b: float2) -> float2 {
    return float2.{
        Min(a.x, b.x),
        Min(a.y, b.y)
    };
}

Min :: (a: float3, b: float3) -> float3 {
    return float3.{
        Min(a.x, b.x),
        Min(a.y, b.y),
        Min(a.z, b.z)
    };
}

Max :: (a: float2, b: float2) -> float2 {
    return float2.{
        Max(a.x, b.x),
        Max(a.y, b.y)
    };
}

Max :: (a: float3, b: float3) -> float3 {
    return float3.{
        Max(a.x, b.x),
        Max(a.y, b.y),
        Max(a.z, b.z)
    };
}

Saturate :: (v: float2) -> float2 {
    return float2.{
        Max(Min(v.x, 1.0), 0.0),
        Max(Min(v.y, 1.0), 0.0)
    };
}

Saturate :: (v: float3) -> float3 {
    return float3.{
        Max(Min(v.x, 1.0), 0.0),
        Max(Min(v.y, 1.0), 0.0),
        Max(Min(v.z, 1.0), 0.0)
    };
}

Length :: (q: quat) -> float {
    return sqrt(q.x*q.x + q.y*q.y + q.z*q.z + q.w*q.w);
}

Normalize :: (q: quat) -> quat {
    L := Length(q);
    if L == 0.0 return .{0.0, 0.0, 0.0, 1.0};
    
    iL := 1.0 / L;
    return q * iL;
}

Lerp :: (a: quat, b: quat, t: float) -> quat {
    return .{
        Lerp(a.x, b.x, t), 
        Lerp(a.y, b.y, t), 
        Lerp(a.z, b.z, t),
        Lerp(a.w, b.w, t)
    };
}

NLerpShortest :: (a: quat, b: quat, t: float) -> quat {
    First := a;
    Second := b;
    if Dot(First, Second) < 0
        Second = -Second;
    return Normalize(Lerp(First, Second, t));
}

QuatFromMatrix :: (m: float4x4) -> quat {
    q: quat = ---;
    Trace := m._11 + m._22 + m._33;
    
    if Trace > 0 {
        s := sqrt(Trace + 1);
        
        q.w = s * 0.5;
        s = 0.5 / s;
        
        q.x = (m.Coef[2][1] - m.Coef[1][2]) * s;
        q.y = (m.Coef[0][2] - m.Coef[2][0]) * s;
        q.z = (m.Coef[1][0] - m.Coef[0][1]) * s;
    } else {
        i := 0;
        if (m.Coef[1][1] > m.Coef[0][0]) i = 1;
        if (m.Coef[2][2] > m.Coef[i][i]) i = 2;
        
        j := (1 << i) & 3;
        k := (1 << j) & 3;
        
        s := sqrt(m.Coef[i][i] - m.Coef[j][j] - m.Coef[k][k] + 1);
        
        q.Components[i] = s * 0.5;
        s = 0.5 / s;
        q.Components[j] = (m.Coef[i][j] + m.Coef[j][i]) * s;
        q.Components[k] = (m.Coef[k][i] + m.Coef[i][k]) * s;
        q.w = (m.Coef[k][j] - m.Coef[j][k]) * s;
    }
    
    return Normalize(q);
};

QuatFromAxisAngle :: (Axis: float3, Turns: float) -> quat {
    q: quat;
    
    s := SinTurns(Turns);
    c := CosTurns(Turns);
    
    return quat.{
        Axis.x * s,
        Axis.y * s,
        Axis.z * s,
        c
    };
}

RotateVector :: (v: float2, Turns: float) -> float2 {
    s := SinTurns(Turns);
    c := CosTurns(Turns);
    
    return float2.{
        v.x*c + v.y*-s,
        v.x*s + v.y*c
    };
}

RotateVector :: (v: float3, q: quat) -> float3 {
    t := Cross(q.xyz, v) * 2.0;
    return v + t * q.w + Cross(q.xyz, t);
}

#scope_file

#import "Basic";
#import "Math";