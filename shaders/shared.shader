
#define short4 min16int4

// SDL_shadercross hangs when using the matrix type
#define matrix float4x4

#define MAX_WEIGHTS 4

#define PI 3.14159265359

float3 unpack_normal(float2 normal) {
    float z = sqrt(1.0 - dot(normal, normal));
    return float3(normal.xy, z);
}

float3 unpack_tangent(float2 tangent) {
    float z = sqrt(1.0 - dot(tangent, tangent));
    return float3(tangent.xy, z);
}

struct Material {
    float roughness;
    float metallic;
    float ambient_occlusion;
};

float distribution_ggx(float3 N, float3 H, float roughness) {
    float a2 = roughness * roughness * roughness * roughness;
    float NdotH = max (dot (N, H), 0.0);
    float denom = (NdotH * NdotH * (a2 - 1.0) + 1.0);
    return a2 / (PI * denom * denom);
}

float geometry_schlick_ggx(float NdotV, float roughness) {
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;
    return NdotV / (NdotV * (1.0 - k) + k);
}

float geometry_smith(float3 N, float3 V, float3 L, float roughness) {
    return geometry_schlick_ggx(max (dot (N, L), 0.0), roughness) *
        geometry_schlick_ggx(max (dot (N, V), 0.0), roughness);
}

float3 fresnel_schlick(float cos_theta, float3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cos_theta, 5.0);
}

float shadow_calculation(Texture2D shadow_map, SamplerState sampler, float4 light_space_position, float3 object_normal, float3 light_dir)
{
    float3 proj_coord = light_space_position.xyz / light_space_position.w;
    proj_coord = proj_coord * 0.5 + 0.5;
    float closest = shadow_map.Sample(sampler, proj_coord.xy).r; 
    float current = proj_coord.z;
    float bias = max(0.005, 0.05 * (1.0 - dot(object_normal, light_dir)));
    float shadow = current - bias > closest  ? 1.0 : 0.3;
    return shadow;
}

float3 lighting_directional(float shadow, float3 object_pos, float3 object_normal, float3 object_colour, Material material, float3 camera_pos, float3 light_dir, float3 light_colour) {
    float3 N = normalize(object_normal);
    float3 V = normalize(camera_pos - object_pos);
    
    float3 F0 = float3(.04, .04, .04);
    F0 = lerp(F0, object_colour, material.metallic);
    
    float3 L = normalize(-light_dir);
    float3 H = normalize(V + L);
    
    float NDF = distribution_ggx(N, H, material.roughness);
    float G = geometry_smith(N, V, L, material.roughness);
    float3 F = fresnel_schlick(max(dot(H, V), 0.0), F0);
    
    float3 kS = F;
    float3 kD = float3(1.0, 1.0, 1.0) - kS;
    kD *= 1.0 - material.metallic;
    
    float3 numerator = NDF * G * F;
    float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
    float3 specular = numerator / denominator;
    
    float NdotL = max(dot(N, L), 0.0);
    float3 Lo = (kD * object_colour / PI + specular) * light_colour * NdotL;
    
    float3 ambient = float3(0.03, 0.03, 0.03) * object_colour * material.ambient_occlusion;
    float3 colour = ambient + Lo * (1.0 - shadow);
    
    colour = colour / (colour + float3(1.0, 1.0, 1.0));
    colour = pow(colour, float3(1.0/2.2, 1.0/2.2, 1.0/2.2));
    
    return colour;
}
/*
float3 lighting_point(float4 light_space_position, float3 object_pos, float3 object_normal, float3 object_colour, Material material, float3 camera_pos, float3 light_pos, float3 light_colour) {
    float3 N = normalize(object_normal);
    float3 V = normalize(camera_pos - object_pos);
    
    float3 F0 = float3(.04);
    F0 = mix(F0, object_colour, material.metallic);
    
    float3 L = normalize(light_pos - object_pos);
    float3 H = normalize(V + L);
    float distance = length(light_pos - object_pos);
    float attenuation = 1.0 / (distance * distance);
    float3 radiance = light_colour * attenuation;
    
    float NDF = distribution_ggx(N, H, material.roughness);
    float G = geometry_smith(N, V, L, material.roughness);
    float3 F = fresnel_schlick(max(dot(H, V), 0.0), F0);
    
    float3 kS = F;
    float3 kD = float3(1.0) - kS;
    kD *= 1.0 - material.metallic;
    
    float3 numerator = NDF * G * F;
    float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
    float3 specular = numerator / denominator;
    
    float NdotL = max(dot(N, L), 0.0);
    float3 Lo = (kD * object_colour / PI + specular) * radiance * NdotL;
    
    float shadow = shadow_calculation(light_space_position, object_normal, light_dir);
    
    float3 ambient = float3(0.03) * object_colour * material.ambient_occlusion;
    float3 colour = ambient + Lo * (1.0 - shadow);
    
    colour = colour / (colour + float3(1.0));
    colour = pow(colour, float3(1.0/2.2));
    
    return colour;
}
*/

float2 get_screen_size(matrix MVP, float3 min_bounds, float3 max_bounds, float2 viewport_size) {
    float4 clip_min = mul(MVP, float4(min_bounds, 1));
    float4 clip_max = mul(MVP, float4(max_bounds, 1));
    
    float3 ndc_min = clip_min.xyz / clip_min.w;
    float3 ndc_max = clip_max.xyz / clip_max.w;
    
    float2 screen_min = (ndc_min.xy * 0.5 + 0.5) * viewport_size;
    float2 screen_max = (ndc_max.xy * 0.5 + 0.5) * viewport_size;
    
    return screen_max - screen_min;
}

float4 snap_ps1(matrix MVP, float4 position, float3 min_bounds, float3 max_bounds, float2 screen_size) {
    float2 res = float2(50, 50);
    
    float2 snapped = position.xy / position.w;
    snapped.x = floor(snapped.x * res.x) / res.x;
    snapped.y = floor(snapped.y * res.y) / res.y;
    snapped *= position.w;
    return float4(snapped, position.zw);
}