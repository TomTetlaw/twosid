#include "shared.shader"

struct Frag_Input {
	float4 ndc_position: SV_Position;
	float3 object_space_position: TEXCOORD0;
	float3 view_space_position: TEXCOORD1;
	float3 world_space_position: TEXCOORD2;
	float2 tex_coord: TEXCOORD6;
	float3 world_space_normal: TEXCOORD7;
	float3 world_space_tangent: TEXCOORD8;
	float3 colour: TEXCOORD9;
	float3 tangent_space_light_dir: TEXCOORD10;
	float3 tangent_space_position: TEXCOORD11;
	float3 tangent_space_view_position: TEXCOORD12;
};

#ifdef VERTEX_SHADER

cbuffer Constant_Buffer : register(b0, space1) {
	row_major matrix world;
	row_major matrix view;
	row_major matrix projection;
	float3 camera_position;
	float pad0;
	float3 diffuse_colour;
	float pad1;
	float3 light_dir;
	float pad2;
};

struct Vertex_Input {
	float3 position: POSITION;
	float2 tex_coord: TEXCOORD0;
    float3 normal: TEXCOORD1;
	float3 tangent: TEXCOORD2;
	float3 bone_weights: TEXCOORD3;
    short4 bone_ids: TEXCOORD4;
};

StructuredBuffer<matrix> skinning_transforms: register(t0, space0);

float3 skinning_contribution(float3 value, float weight, short4 bone_ids, int index) {
	float mask = max(float(bone_ids[index] + 1), 1.0);
	return value + mul(skinning_transforms[bone_ids[index]], float4(value, 1)).xyz * weight * mask;
}

float3 skinning_calculation(float3 model_value, float3 weights, short4 bone_ids) {
	float4 weights4 = float4(weights, 1.0 - sum(weights));
	model_value = skinning_contribution(model_value, weights4.x, bone_ids, 0);
	model_value = skinning_contribution(model_value, weights4.y, bone_ids, 1);
	model_value = skinning_contribution(model_value, weights4.z, bone_ids, 2);
	model_value = skinning_contribution(model_value, weights4.w, bone_ids, 3);
	return model_value;
}

Frag_Input vertex_main(Vertex_Input input) {
    float3 model_position = skinning_calculation(input.position, input.bone_weights, input.bone_ids);
    float3 model_normal = skinning_calculation(input.normal, input.bone_weights, input.bone_ids);
	float3 model_tangent = skinning_calculation(input.tangent, input.bone_weights, input.bone_ids);

	matrix M = world;
	matrix MV = mul(view, world);
	matrix MVP = mul(projection, mul(view, world));

	float3 world_position = mul(M, float4(model_position, 1)).xyz;
	float3 view_position = mul(MV, float4(model_position, 1)).xyz;
	float4 ndc_position = mul(MVP, float4(model_position, 1));

	float3x3 linear_model_transform = float3x3(M[0].xyz, M[1].xyz, M[2].xyz);
    linear_model_transform = transpose(linear_model_transform);

	float3 world_normal = normalize(mul(linear_model_transform, model_normal));
	float3 world_tangent = normalize(mul(linear_model_transform, model_tangent));

	float3 bitangent = normalize(cross(world_normal, world_tangent));
	if (dot(world_normal, bitangent) < 0) bitangent = normalize(bitangent * -1);

    float3x3 TBN = transpose(float3x3(world_tangent, bitangent, world_normal));

	Frag_Input output;
	output.ndc_position = ndc_position;
	output.object_space_position = model_position;
	output.world_space_position = world_position;
	output.view_space_position = view_position;
	output.tex_coord = input.tex_coord;
	output.world_space_normal = world_normal;
	output.world_space_tangent = world_tangent;
	output.colour = diffuse_colour;
	output.tangent_space_light_dir = mul(TBN, light_dir);
	output.tangent_space_position = mul(TBN, world_position);
	output.tangent_space_view_position = mul(TBN, camera_position);
	return output;
}

#endif

#ifdef FRAGMENT_SHADER

cbuffer Constant_Buffer : register(b0, space3) {
	float3 light_colour;
	float pad2;
	float4 material_params;
	float3 depth_planes;
	float pad4;
	row_major matrix light_matrix;
	int frag_debug_mode;
	float3 pad5;
};

Texture2D shadow_map: register(t0, space2);
Texture2D diffuse_map: register(t1, space2);
Texture2D normal_map: register(t2, space2);
Texture2D rmaoh_map: register(t3, space2);

SamplerState shadow_sampler: register(s0, space2);
SamplerState diffuse_sampler: register(s1, space2);
SamplerState normal_sampler: register(s2, space2);
SamplerState rmaoh_sampler: register(s3, space2);

float shadow_calculation(float depth, float2 shadow_tex_coord, float bias) {
	float4 shadow_sample = shadow_map.Sample(shadow_sampler, shadow_tex_coord);
	return depth - bias > shadow_sample.r ? 0.0 : -0.2;
}

float4 fragment_main(Frag_Input input): SV_Target {
	float2 tex_coord = input.tex_coord * material_params.w;
	
	float3 diffuse = diffuse_map.Sample(diffuse_sampler, tex_coord).xyz;
	diffuse = input.colour * pow(diffuse, float3(2.2, 2.2, 2.2));

	float3 map_normal = normal_map.Sample(normal_sampler, tex_coord).xyz;
	map_normal = map_normal * 2 - 1;
	map_normal.x = -map_normal.x;
	map_normal = normalize(map_normal);

	float4 rmaoh = rmaoh_map.Sample(rmaoh_sampler, tex_coord);
	rmaoh = float4(rmaoh.xyz * material_params.xyz, rmaoh.w);

	Material material;
	material.roughness = clamp(rmaoh.x, 0.0, 1.0);
	material.metallic = clamp(rmaoh.y, 0.0, 1.0);
	material.ambient_occlusion = clamp(rmaoh.z, 0.0, 1.0);

	float4 light_space_position = mul(light_matrix, float4(input.world_space_position, 1));

	float3 shadow_coord = light_space_position.xyz / light_space_position.w;
	shadow_coord = shadow_coord * 0.5 + 0.5;

	float2 shadow_tex_coord = shadow_coord.xy;
	shadow_tex_coord.y = 1 - shadow_tex_coord.y;

	float spread = 1400.0;
	float2 poisson0 = float2(-0.94201624, -0.39906216) / spread;
	float2 poisson1 = float2(0.94558609, -0.76890725) / spread;
	float2 poisson2 = float2(-0.094184101, -0.92938870) / spread;
	float2 poisson3 = float2(0.34495938, 0.29387760) / spread;

	int x, y;
	shadow_map.GetDimensions(x, y);
	float2 texel_size = 1.0 / float2(x, y);

	float shadow = 1;
	float bias = max(0.05 * (1.0 - dot(map_normal, input.tangent_space_light_dir)), 0.005);
	shadow += shadow_calculation(shadow_coord.z, shadow_tex_coord + poisson0 + random(float4(input.world_space_position, 0.0)) * texel_size, bias);
	shadow += shadow_calculation(shadow_coord.z, shadow_tex_coord + poisson1 + random(float4(input.world_space_position, 1.0)) * texel_size, bias);
	shadow += shadow_calculation(shadow_coord.z, shadow_tex_coord + poisson2 + random(float4(input.world_space_position, 2.0)) * texel_size, bias);
	shadow += shadow_calculation(shadow_coord.z, shadow_tex_coord + poisson3 + random(float4(input.world_space_position, 3.0)) * texel_size, bias);

	float3 colour = lighting_directional(shadow, input.tangent_space_position, map_normal, input.tangent_space_view_position, input.tangent_space_light_dir, diffuse, material, light_colour);

	if (frag_debug_mode == 1) {
		//colour = float3(shadow_tex_coord, 0);
		colour = float3(shadow, 0, 0);
	}

	return float4(colour, 1);
}

#endif