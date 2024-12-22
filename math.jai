
 RoundUp :: ceil;
RoundDown :: floor;
Mod :: fmod_cycling;
SquareRoot :: sqrt;

TAU   :: cast(float32) 6.283185;
TAU64 :: 6.28318530717958648;

PI    :: cast(float32) 3.1415927;
PI64  :: 3.141592653589793;

Deg2Rad :: PI / 180.0;
Rad2Deg :: 180.0 / PI;

Turn2Rad :: 2 * PI;
Rad2Turn :: 1.0 / (2 * PI);

Turn2Deg :: PI;
Deg2Turn :: 1.0 / 360.0;

Clamp :: (Value: $T, Min: T, Max: T) -> T {
    if Value < Min return Min;
    if Value > Max return Max;
    return Value;
}

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
    t -= 0.25 + RoundDown(t + 0.25);
    t *= 16.0 * (Abs(t) - 0.5);
    t += 0.225 * t * (Abs(t) - 1.0);
    return t;
}

SinTurns :: (t: float) -> float {
    return CosTurns(0.25 - t);
}

TanTurns :: (t: float) -> float {
    S := SinTurns(t);
    C := CosTurns(t);
    if C == 0.0 return 0.0;
    return S / C;
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
    
#place y;
    yz: float2;
}

float4 :: struct {
    x, y, z, w: float;
    
#place x;
    Components: [4] float;
    
#place x;
    xy: float2;
    
#place y;
    yz: float2;
    
#place z;
    zw: float2;
    
#place x;
    xyz: float3;
    
#place y;
    yzw: float3;
}

quat :: struct {
    x, y, z: float;
    w := 1.0;
    
#place x;
    Components: [4] float;
    
#place x;
    xyz: float3 = ---;
};

xy :: (xy: float) -> float2 {
    return .{xy, xy};
}

xyz :: (xyz: float) -> float3 {
    return .{xyz, xyz, xyz};
}

xyz :: (xy: float2, z: float) -> float3 {
    return .{xy.x, xy.y, z};
}

xyz :: (x: float, yz: float2) -> float3 {
    return .{x, yz.x, yz.y};
}

yzx :: (v: float3) -> float3 {
    return .{v.y, v.z, v.x};
}

xyzw :: (xyzw: float) -> float4 {
    return .{xyzw, xyzw, xyzw, xyzw};
}

xyzw :: (xyz: float3, w: float) -> float4 {
    return .{xyz.x, xyz.y, xyz.z, w};
}

xyzw :: (x: float, yzw: float3) -> float4 {
    return .{x, yzw.x, yzw.y, yzw.z};
}

xyzw :: (xy: float2, zw: float2) -> float4 {
    return .{xy.x, xy.y, zw.x, zw.y};
}

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
    return SquareRoot(v.x*v.x + v.y*v.y);
}

Length :: (v: float3) -> float {
    return SquareRoot(v.x*v.x + v.y*v.y + v.z*v.z);
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

NormalizeSquared :: (v: float2) -> float2 {
    L := LengthSquared(v);
    if L == 0.0 return .{1.0, 0.0};
    
    iL := 1.0 / L;
    return v * iL;
}

NormalizeSquared :: (v: float3) -> float3 {
    L := LengthSquared(v);
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

Sign :: (f: float) -> float {
    if f < 0.0 return -1.0;
    return 1.0;
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
    return SquareRoot(q.x*q.x + q.y*q.y + q.z*q.z + q.w*q.w);
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
        s := SquareRoot(Trace + 1);
        
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
        
        s := SquareRoot(m.Coef[i][i] - m.Coef[j][j] - m.Coef[k][k] + 1);
        
        q.Components[i] = s * 0.5;
        s = 0.5 / s;
        q.Components[j] = (m.Coef[i][j] + m.Coef[j][i]) * s;
        q.Components[k] = (m.Coef[k][i] + m.Coef[i][k]) * s;
        q.w = (m.Coef[k][j] - m.Coef[j][k]) * s;
    }
    
    return Normalize(q);
};

QuatFromAxisAngle :: (v: float3, Turns: float) -> quat {
    s := SinTurns(Turns * 0.5);
    c := CosTurns(Turns * 0.5);
    
    Result := quat.{
        v.x * s,
        v.y * s,
        v.z * s,
        c
    };
    
    if Result.x < -1 || Result.x > 1 print("Result.x: %\n", Turns);
    if Result.y < -1 || Result.y > 1 print("Result.y: %\n", Turns);
    if Result.z < -1 || Result.z > 1 print("Result.z: %\n", Turns);
    if Result.w < -1 || Result.w > 1 print("Result.w: %\n", Turns);
    
    return Result;
}

RotateVector :: (v: float2, Turns: float) -> float2 {
    s := SinTurns(Turns);
    c := CosTurns(Turns);
    
    return float2.{
        v.x*c + v.y*s,
        v.x*-s + v.y*c
    };
}

RotateVector :: (v: float3, q: quat) -> float3 {
    t := Cross(q.xyz, v) * 2.0;
    return v + t * q.w + Cross(q.xyz, t);
}

RotateVectorAxes :: (v: float3, q: quat, a: float4) -> float3 {
    Qa := q * a;
    t := Cross(Qa.xyz, v) * 2.0;
    return v + t * Qa.w + Cross(Qa.xyz, t);
}

#scope_file

#import "Basic";

using,only(ceil,floor,abs,sqrt,fmod_cycling) Math :: #import "Math";