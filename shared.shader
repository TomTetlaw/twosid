
#define MAX_BONES 1000
#define MAX_WEIGHTS 4

float3 unpack_normal(float2 normal) {
    float z = sqrt(1.0 - dot(normal, normal));
    return float3(normal.xy, z);
}

float3 unpack_tangent(float2 tangent) {
    float z = sqrt(1.0 - dot(tangent, tangent));
    return float3(tangent.xy, z);
}