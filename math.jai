
Deg2Rad :: PI / 180.0;
Rad2Deg :: 180.0 / PI;

Turn2Rad :: 2 * PI;
Rad2Turn :: 1.0 / (2 * PI);

Turn2Deg :: PI;
Deg2Turn :: 1.0 / 360.0;

float2 :: Vector2;
float3 :: Vector3;
float4 :: Vector4;
float4x4 :: Matrix4;
quat :: Quaternion;

Dot :: (a: float3, b: float3) -> float {
    return a.x*b.x + a.y*b.y + a.z*b.z;
}

Dot :: (a: quat, b: quat) -> float {
    return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w;
}

Length :: (v: float3) -> float {
    return sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
}

Lerp :: (a: float, b: float, t: float) -> float {
    return a + (b - a) * t;
}

Lerp :: (a: float2, b: float2, t: float) -> float2 {
    return .{Lerp(a.x, b.x, t), Lerp(a.y, b.y, t)};
}

Lerp :: (a: float3, b: float3, t: float) -> float3 {
    return .{Lerp(a.x, b.x, t), Lerp(a.y, b.y, t), Lerp(a.z, b.z, t)};
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

TanTurnsSafe :: (t: float) -> float {
    CosValue := CosTurns(t);
    if CosValue == 0.0 return ifx t > 0.0 then FLOAT32_INFINITY else -FLOAT32_INFINITY;
    return SinTurns(t) / CosValue;
}

TanTurns :: (t: float) -> float {
    CosValue := CosTurns(t);
    return SinTurns(t) / CosValue;
}

v4 :: (v: float3, w: float) -> float4 {
    return .{v.x, v.y, v.z, w};
}

Vec3Rotate :: (v: float3, q: quat) -> float3 {
    rotate(*v, q);
    return v;
}

Mat4Identity :: () -> float4x4 {
    m: float4x4 = ---;
    identity(*m);
    return m;
}

Mat4LookAt :: (Pos: float3, Target: float3) -> float4x4 {
    Result := make_look_at_matrix(Pos, Target, .{0, 1, 0}, false);
    return Result;
}

// thanks to this article!
// https://johannesugb.github.io/gpu-programming/setting-up-a-proper-vulkan-Projection-matrix/
Mat4ViewToVulkanNdc :: () -> float4x4 {
    Result: float4x4;
    
    Result._12 = -1;
    Result._23 = 1;
    Result._31 = 1;
    Result._44 = 1;
    
    return Result;
}

Mat4Projection :: (Fov: float, Aspect: float, Near: float, Far: float, $TransformFromViewSpace := true) -> Matrix4 {
    Result := make_projection_matrix(Fov, Aspect, Near, Far);
#if TransformFromViewSpace Result = Result * Mat4ViewToVulkanNdc();
    return Result;
}

Mat4Ortho :: (Left: float, Right: float, Bottom: float, Top: float, Near: float, Far: float) -> float4x4 {
    Result := orthographic_projection_matrix(Left, Right, Bottom, Top, Near, Far);
    return Result;
}

Append :: (v: float3, w: float) -> float4 {
    return float4.{v.x, v.y, v.z, w};
}

Mat4Inverse :: inverse;

Mat4Translation :: make_translation_matrix4;

Mat4Rotation :: (q: quat) -> float4x4 {
    m := Mat4Identity();
    set_rotation(*m, q);
    return m;
}

Mat4Scale :: make_scale_matrix4;

Mat4Transpose :: transpose;

QuatFromMatrix :: get_rotation;

NLerpShortest :: (a: quat, b: quat, t: float) -> quat {
    First := a;
    Second := b;
    if Dot(First, Second) < 0
        Second = -Second;
    return nlerp(First, Second, t);
}

QuatAxisAngle :: (Axis: float3, Turns: float) -> quat {
    q: quat;
    
    St := SinTurns(Turns);
    Ct := CosTurns(Turns);
    
    q.x = Axis.x * St;
    q.y = Axis.y * St;
    q.z = Axis.z * St;
    q.w = Ct;
    
    return q;
}

Mat4Decompose :: (m: float4x4) -> float3, quat, float3 {
	Translation := float3.{
        m._14,
        m._24,
        m._34
    };
    
	Rotation := QuatFromMatrix(m);
    
	Scale := float3.{
        Length(float3.{m._11, m._21, m._31}),
        Length(float3.{m._12, m._22, m._32}),
        Length(float3.{m._13, m._23, m._33})
    };
    
	return Translation, Rotation, Scale;
}

#scope_file

#import "Basic";
#import "Math";