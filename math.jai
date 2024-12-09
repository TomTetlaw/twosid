
deg2rad :: PI / 180.0;
rad2deg :: 180.0 / PI;

turn2rad :: 2 * PI;
rad2turn :: 1.0 / (2 * PI);

turn2deg :: PI;
deg2turn :: 1.0 / 360.0;

Vec2 :: Vector2;
Vec3 :: Vector3;
Vec4 :: Vector4;
Mat4 :: Matrix4;

cos_turns :: (t: float) -> float {
    t -= 0.25 + floor(t + 0.25);
    t *= 16.0 * (abs(t) - 0.5);
    t += 0.225 * t * (abs(t) - 1.0);
    return t;
}

sin_turns :: (t: float) -> float {
    return cos_turns(0.25 - t);
}

tan_turns_safe :: (t: float) -> float {
    cos_value := cos_turns(t);
    if cos_value == 0.0 return ifx t > 0.0 then FLOAT32_INFINITY else -FLOAT32_INFINITY;
    return sin_turns(t) / cos_value;
}

tan_turns :: (t: float) -> float {
    cos_value := cos_turns(t);
    return sin_turns(t) / cos_value;
}

v4 :: (v: Vec3, w: float) -> Vec4 {
    return .{v.x, v.y, v.z, w};
}

vec3_rotate :: (v: Vec3, q: Quaternion) -> Vec3 {
    rotate(*v, q);
    return v;
}

mat4_identity :: () -> Mat4 {
    m: Mat4 = ---;
    identity(*m);
    return m;
}

mat4_look_at :: (pos: Vec3, target: Vec3) -> Mat4 {
    result := make_look_at_matrix(pos, target, .{0, 1, 0}, false);
    return result;
}

// thanks to this article!
// https://johannesugb.github.io/gpu-programming/setting-up-a-proper-vulkan-projection-matrix/
mat4_view_to_vulkan_ndc :: () -> Mat4 {
    result: Mat4;
    
    result._12 = -1;
    result._23 = 1;
    result._31 = 1;
    result._44 = 1;
    
    return result;
}

mat4_projection :: (fov: float, aspect: float, near: float, far: float, $transform_from_view_space := true) -> Matrix4 {
    result := make_projection_matrix(fov, aspect, near, far);
#if transform_from_view_space result = result * mat4_view_to_vulkan_ndc();
    return result;
}

mat4_ortho :: (left: float, right: float, bottom: float, top: float, near: float, far: float) -> Mat4 {
    result := orthographic_projection_matrix(left, right, bottom, top, near, far);
    return result;
}

append :: (v: Vec3, w: float) -> Vec4 {
    return Vec4.{v.x, v.y, v.z, w};
}

mat4_inverse :: inverse;

mat4_translation :: make_translation_matrix4;

mat4_rotation :: (q: Quaternion) -> Mat4 {
    m := mat4_identity();
    set_rotation(*m, q);
    return m;
}

mat4_scale :: make_scale_matrix4;

mat4_transpose :: transpose;

quat_from_matrix :: get_rotation;

nlerp_shortest :: (a: Quaternion, b: Quaternion, t: float) -> Quaternion
{
    first := a;
    second := b;
    if dot(first, second) < 0
        second = -second;
    return nlerp(first, second, t);
}

quat_axis_angle :: (axis: Vec3, turns: float) -> Quaternion {
    q: Quaternion;
    
    st := sin_turns(turns);
    ct := cos_turns(turns);
    
    q.x = axis.x * st;
    q.y = axis.y * st;
    q.z = axis.z * st;
    q.w = ct;
    
    return q;
}

mat4_decompose :: (m: Mat4) -> Vector3, Quaternion, Vector3 {
	translation := Vec3.{
        m._14,
        m._24,
        m._34
    };
    
	rotation := quat_from_matrix(m);
    
	scale := Vec3.{
        length(Vec3.{m._11, m._21, m._31}),
        length(Vec3.{m._12, m._22, m._32}),
        length(Vec3.{m._13, m._23, m._33})
    };
    
	return translation, rotation, scale;
}

#scope_file

#import "Basic";
#import "Math";