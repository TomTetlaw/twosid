
#define short4 min16int4

// SDL_shadercross hangs when using the matrix type
#define matrix float4x4

#define MAX_WEIGHTS 4

#define PI 3.14159265359

float sum(float3 v) {
	return v.x + v.y + v.z;
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

float3 shadow_projection_coord(float4 light_space_position) {
    float3 proj_coord = light_space_position.xyz / light_space_position.w;
	return proj_coord * 0.5 + 0.5;
}

float shadow_calculation(float shadow_sample, float depth, float3 object_normal, float3 light_dir) {
    float bias = max(0.005, 0.05 * (1.0 - dot(object_normal, light_dir)));
    return depth - bias > shadow_sample ? 1.0 : 0.3;
}

float3 lighting_directional(float shadow, float3 object_pos, float3 object_normal, float3 object_colour, Material material, float3 camera_pos, float3 light_dir, float3 light_colour) {
    float3 N = object_normal;
    float3 V = normalize(camera_pos - object_pos);
    
    float3 F0 = float3(.04, .04, .04);
    F0 = lerp(F0, object_colour, material.metallic);
    
    float3 L = normalize(-light_dir);
    float3 H = normalize(V + L);
    float3 radiance = light_colour; // for directional lights this is equal everywhere

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
float3 lighting_point(float shadow, float3 object_pos, float3 object_normal, float3 object_colour, Material material, float3 camera_pos, float3 light_position, float3 light_dir, float3 light_colour) {
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

float3 slerp(float3 a, float3 b, float t) {
    float dot_product = dot(a, b);
    float theta = acos(dot_product) * t;
    float3 relative = normalize(b - a * dot_product);
    return a * cos(theta) + relative * sin(theta);
}

float4 fractal_texture(Texture2D map, SamplerState sampler, float2 tex_coord, float depth) {
    float LOD = log(depth);
    float LOD_floor = floor(LOD);
    float LOD_fract = LOD - LOD_floor;
    
    float4 tex0 = map.Sample(sampler, tex_coord / exp(LOD_floor - 1.0));
    float4 tex1 = map.Sample(sampler, tex_coord / exp(LOD_floor + 0.0));
    float4 tex2 = map.Sample(sampler, tex_coord / exp(LOD_floor + 1.0));
    
    return (tex1 + lerp(tex0, tex2, LOD_fract)) * 0.5;
}

// https://www.shadertoy.com/view/mds3R4
float4 fractal_texture_mip(Texture2D map, SamplerState sampler, float2 tex_coord, float depth) {
    float LOD = log(depth);
    float LOD_floor = floor(LOD);
    float LOD_fract = LOD - LOD_floor;
    
    float2 t0 = tex_coord / exp(LOD_floor - 1.0);
    float2 t1 = tex_coord / exp(LOD_floor + 0.0);
    float2 t2 = tex_coord / exp(LOD_floor + 1.0);
    
    float2 dx = ddx(tex_coord) / depth * exp(1.0);
    float2 dy = ddy(tex_coord) / depth * exp(1.0);
    
    float4 tex0 = map.SampleGrad(sampler, t0, dx, dy);
    float4 tex1 = map.SampleGrad(sampler, t1, dx, dy);
    float4 tex2 = map.SampleGrad(sampler, t2, dx, dy);
    
    return (tex1 + lerp(tex0, tex2, LOD_fract)) * 0.5;
}

// http://www.thetenthplanet.de/archives/1180
float3x3 cotangent_frame(float3 N, float3 V, float2 tex_coord) {
    float2 t1 = ddx(tex_coord);
    float2 t2 = ddy(tex_coord);
    float3 p1 = cross(N, ddx(V));
	float3 p2 = cross(ddy(V), N);

    float3 T = p2 * t1.x + p1 * t2.x;
    float3 B = p2 * t1.y + p1 * t2.y;

    float I = rsqrt(max(dot(T, T), dot(B, B)));
    return float3x3(T * I, B * I, N);
}

float3 unpack_blend_normal(float3 camera_position, float3 position, float2 tex_coord, float3 N, float3 map_normal) {
    float3 V = normalize(camera_position - position);
    float3x3 TBN = cotangent_frame(N, -V, tex_coord);
    return normalize(mul(TBN, map_normal));
}