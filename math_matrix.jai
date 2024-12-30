
float2x2 :: struct {
    _11, _12: float;
    _21, _22: float;
    
#place _11; 
    Rows: [2] float2 = ---;
#place _11; 
    Coef: [2][2] float = ---;
#place _11; 
    Floats: [4] float = ---;
}

Determinant :: (m: float2x2) -> float {
    return m._11 * m._22 - m._12 * m._21;
}

float4x4 :: struct {
    _11, _12, _13, _14 : float;
    _21, _22, _23, _24 : float;
    _31, _32, _33, _34 : float;
    _41, _42, _43, _44 : float;
    
#place _11; 
    Rows: [4] float4 = ---;
#place _11; 
    Coef: [4][4] float = ---;
#place _11; 
    Floats: [16] float = ---;
}

IdentityMatrix :: float4x4.{
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0
};

TranslateMatrix :: (m: float4x4, v: float3) -> float4x4 {
    Result := m;
    
    Result.Coef[0][3] += Result.Coef[0][0]*v.x + Result.Coef[0][1]*v.y + Result.Coef[0][2]*v.z;
    Result.Coef[1][3] += Result.Coef[1][0]*v.x + Result.Coef[1][1]*v.y + Result.Coef[1][2]*v.z;
    Result.Coef[2][3] += Result.Coef[2][0]*v.x + Result.Coef[2][1]*v.y + Result.Coef[2][2]*v.z;
    Result.Coef[3][3] += Result.Coef[3][0]*v.x + Result.Coef[3][1]*v.y + Result.Coef[3][2]*v.z;
    
    return Result;
}

LookAtMatrix :: (Pos: float3, Target: float3) -> float4x4 {
    Forward := Normalize(Target - Pos);
    Left := Normalize(Cross(.{0, 1, 0}, Forward));
    Up := Normalize(Cross(Forward, Left));
    
    Rotation := MatrixFromRows(Left * -1, Up, Forward * -1);
    Result := TranslateMatrix(Rotation, -Pos);
    
    return Result;
}

// thanks to this article!
// https://johannesugb.github.io/gpu-programming/setting-up-a-proper-vulkan-Projection-matrix/
ViewToProjectionMatrix :: () -> float4x4 {
    Result: float4x4;
    
    Result._12 = -1;
    Result._23 = 1;
    Result._31 = -1;
    Result._44 = 1;
    
    return Result;
}

ProjectionMatrix :: (FovTurns: float, Aspect: float, Near: float, Far: float, $TransformFromViewSpace := true) -> float4x4 {
    Result := IdentityMatrix;
    
    TanTheta := TanTurns(FovTurns * 0.5);
    CotTheta := 1 / TanTheta;
    
    n := Near;
    f := Far;
    d := 1 / (f - n);
    
    Result._11 = CotTheta / Aspect;
    Result._22 = CotTheta;
    Result._33 = -(f + n) * d;
    Result._43 = -1;
    Result._34 = -2 * f * n * d;
    Result._44 = 0;
    
#if TransformFromViewSpace Result = Result * ViewToProjectionMatrix();
    
    return Result;
}

OrthoProjectionMatrix :: (Left: float, Right: float, Bottom: float, Top: float, Near: float, Far: float) -> float4x4 {
    Result: float4x4;
    
    Result._11 = 2.0 / (Right - Left);
    Result._14 = -(Right + Left) / (Right - Left);
    
    Result._22 = 2.0 / (Top - Bottom);
    Result._24 = -(Top + Bottom) / (Top - Bottom);
    
    Result._33 = -2 / (Far - Near);
    Result._34 = -(Far + Near) / (Far - Near);
    Result._44 = 1.0;
    
    return Result;
}

TranslationMatrix:: (t: float3) -> float4x4 {
    Result := IdentityMatrix;
    
    Result._14 = t.x;
    Result._24 = t.y;
    Result._34 = t.z;
    
    return Result;
}

RotationMatrix :: (q: quat) -> float4x4 {
    m := IdentityMatrix;
    s :: 2.0;
    
    xs := q.x * s;
    ys := q.y * s;
    zs := q.z * s;
    
    wx := q.w * xs;
    wy := q.w * ys;
    wz := q.w * zs;
    
    _xx := q.x * xs;
    xy := q.x * ys;
    xz := q.x * zs;
    
    yy := q.y * ys;
    yz := q.y * zs;
    zz := q.z * zs;
    
    m._11 = 1.0 - (yy + zz);
    m._12 = xy - wz;
    m._13 = xz + wy;
    
    m._21 = xy + wz;
    m._22 = 1.0 - (_xx + zz);
    m._23 = yz - wx;
    
    m._31 = xz - wy;
    m._32 = yz + wx;
    m._33 = 1.0 - (_xx + yy);
    
    return m;
}

ScaleMatrix :: (v: float3) -> float4x4 {
    Result := IdentityMatrix;
    
    Result._11 = v.x;
    Result._22 = v.y;
    Result._33 = v.z;
    
    return Result;
}

TransposeMatrix :: (m: float4x4) -> float4x4 {
    r: float4x4 = ---;
    
    for i: 0..3 for j: 0..3 {
        r.Coef[i][j] = m.Coef[j][i];
    }
    
    return r;
}

MatrixFromRows :: (x: float3, y: float3, z: float3) -> float4x4 {
    Result: float4x4;
    Result._11 = x.x;
    Result._12 = x.y;
    Result._13 = x.z;
    
    Result._21 = y.x;
    Result._22 = y.y;
    Result._23 = y.z;
    
    Result._31 = z.x;
    Result._32 = z.y;
    Result._33 = z.z;
    
    Result._44 = 1;
    
    return Result;
}

DecomposeMatrix :: (m: float4x4) -> float3, quat, float3 {
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

AdjugateMatrix :: (a: float4x4) -> float4x4 {
    m: float4x4;
    
    m._11 =  a._22 * (a._33 * a._44 - a._34 * a._43) - 
        a._23 * (a._32 * a._44 - a._34 * a._42) + 
        a._24 * (a._32 * a._43 - a._33 * a._42);
    m._12 = -(a._21 * (a._33 * a._44 - a._34 * a._43) - 
              a._23 * (a._31 * a._44 - a._34 * a._41) + 
              a._24 * (a._31 * a._43 - a._33 * a._41));
    m._13 =  a._21 * (a._32 * a._44 - a._34 * a._42) - 
        a._22 * (a._31 * a._44 - a._34 * a._41) + 
        a._24 * (a._31 * a._42 - a._32 * a._41);
    m._14 = -(a._21 * (a._32 * a._43 - a._33 * a._42) - 
              a._22 * (a._31 * a._43 - a._33 * a._41) + 
              a._23 * (a._31 * a._42 - a._32 * a._41));
    
    m._21 = -(a._12 * (a._33 * a._44 - a._34 * a._43) - 
              a._13 * (a._32 * a._44 - a._34 * a._42) + 
              a._14 * (a._32 * a._43 - a._33 * a._42));
    m._22 =  a._11 * (a._33 * a._44 - a._34 * a._43) - 
        a._13 * (a._31 * a._44 - a._34 * a._41) + 
        a._14 * (a._31 * a._43 - a._33 * a._41);
    m._23 = -(a._11 * (a._32 * a._44 - a._34 * a._42) - 
              a._12 * (a._31 * a._44 - a._34 * a._41) + 
              a._14 * (a._31 * a._42 - a._32 * a._41));
    m._24 =  a._11 * (a._32 * a._43 - a._33 * a._42) - 
        a._12 * (a._31 * a._43 - a._33 * a._41) + 
        a._13 * (a._31 * a._42 - a._32 * a._41);
    
    m._31 =  a._12 * (a._23 * a._44 - a._24 * a._43) - 
        a._13 * (a._22 * a._44 - a._24 * a._42) + 
        a._14 * (a._22 * a._43 - a._23 * a._42);
    m._32 = -(a._11 * (a._23 * a._44 - a._24 * a._43) - 
              a._13 * (a._21 * a._44 - a._24 * a._41) + 
              a._14 * (a._21 * a._43 - a._23 * a._41));
    m._33 =  a._11 * (a._22 * a._44 - a._24 * a._42) - 
        a._12 * (a._21 * a._44 - a._24 * a._41) + 
        a._14 * (a._21 * a._42 - a._22 * a._41);
    m._34 = -(a._11 * (a._22 * a._43 - a._23 * a._42) - 
              a._12 * (a._21 * a._43 - a._23 * a._41) + 
              a._13 * (a._21 * a._42 - a._22 * a._41));
    
    m._41 = -(a._12 * (a._23 * a._34 - a._24 * a._33) - 
              a._13 * (a._22 * a._34 - a._24 * a._32) + 
              a._14 * (a._22 * a._33 - a._23 * a._32));
    m._42 =  a._11 * (a._23 * a._34 - a._24 * a._33) - 
        a._13 * (a._21 * a._34 - a._24 * a._31) + 
        a._14 * (a._21 * a._33 - a._23 * a._31);
    m._43 = -(a._11 * (a._22 * a._34 - a._24 * a._32) - 
              a._12 * (a._21 * a._34 - a._24 * a._31) + 
              a._14 * (a._21 * a._32 - a._22 * a._31));
    m._44 =  a._11 * (a._22 * a._33 - a._23 * a._32) - 
        a._12 * (a._21 * a._33 - a._23 * a._31) + 
        a._13 * (a._21 * a._32 - a._22 * a._31);
    
    return TransposeMatrix(m);
}

InverseMatrix :: (m: float4x4, Epsilon := 0.001) -> float4x4, bool {
    Det := m._11 * (m._22 * (m._33 * m._44 - m._34 * m._43) - m._23 * (m._32 * m._44 - m._34 * m._42) + m._24 * (m._32 * m._43 - m._33 * m._42))
        - m._12 * (m._21 * (m._33 * m._44 - m._34 * m._43) - m._23 * (m._31 * m._44 - m._34 * m._41) + m._24 * (m._31 * m._43 - m._33 * m._41))
        + m._13 * (m._21 * (m._32 * m._44 - m._34 * m._42) - m._22 * (m._31 * m._44 - m._34 * m._41) + m._24 * (m._31 * m._42 - m._32 * m._41))
        - m._14 * (m._21 * (m._32 * m._43 - m._33 * m._42) - m._22 * (m._31 * m._43 - m._33 * m._41) + m._23 * (m._31 * m._42 - m._32 * m._41));
    
    if Abs(Det) < Epsilon return m, false;
    
    iDet := 1 / Det;
    Adj := AdjugateMatrix(m);
    return iDet * Adj, true;
}

using,only(tan, make_look_at_matrix) Math :: #import "Math";