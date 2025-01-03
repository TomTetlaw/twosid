#include "shared.shader"

struct Frag_Input {
	float4 cs_position: SV_Position;
	float3 os_position: TEXCOORD0;
	float3 vs_position: TEXCOORD1;
	float3 ws_position: TEXCOORD2;
	float3 ts_position: TEXCOORD3;
	float3 ts_light_dir: TEXCOORD4;
	float3 ts_view_pos: TEXCOORD5;
	float2 tex_coord: TEXCOORD6;
	float4 colour: TEXCOORD7;

	nointerpolation float4 material_params: TEXCOORD9;
	nointerpolation float4 feature_flags: TEXCOORD10;
};

#ifdef VERTEX_SHADER

cbuffer Constant_Buffer : register(b0, space1) {
	row_major float4x4 view;
	row_major float4x4 projection;
	float3 view_pos;
	float pad0;
	float3 light_dir;
	float pad2;
	float4 time;
};

struct Instance_Data {
	row_major float4x4 transform;
	float4 diffuse_colour;
	float4 material_params;
	float4 feature_flags;
};

struct Skinning_Data {
	row_major float4x4 transform;
};

StructuredBuffer<Skinning_Data> skinning_transforms: register(t0, space0);
StructuredBuffer<Instance_Data> instance_data: register(t1, space0);

struct Vertex_Input {
	float3 position: POSITION;
	float2 tex_coord: TEXCOORD0;
    float3 normal: TEXCOORD1;
	float3 tangent: TEXCOORD2;
	float3 bone_weights: TEXCOORD3;
    short4 bone_ids: TEXCOORD4;
};

float3 skinning_contribution(float3 value, float weight, short bone_id) {
	if (bone_id == -1) return value;
	float4x4 transform = skinning_transforms[bone_id].transform;
	return value + mul(transform, float4(value, 1)).xyz * weight;
}

float3 skinning_calculation(float3 model_value, float3 weights, short4 bone_ids) {
	float4 weights4 = float4(weights, 1.0 - sum(weights));
	model_value = skinning_contribution(model_value, weights4.x, bone_ids.x);
	model_value = skinning_contribution(model_value, weights4.y, bone_ids.y);
	model_value = skinning_contribution(model_value, weights4.z, bone_ids.z);
	model_value = skinning_contribution(model_value, weights4.w, bone_ids.w);
	return model_value;
}

Frag_Input vertex_main(Vertex_Input input, uint instance_id: SV_InstanceId) {
	Instance_Data instance = instance_data[instance_id];

    float3 model_position = skinning_calculation(input.position, input.bone_weights, input.bone_ids);
    float3 model_normal = skinning_calculation(input.normal, input.bone_weights, input.bone_ids);
	float3 model_tangent = skinning_calculation(input.tangent, input.bone_weights, input.bone_ids);

	float4x4 M = instance.transform;
	float4x4 MV = mul(view, M);
	float4x4 MVP = mul(projection, mul(view, M));

	float3 world_position = mul(M, float4(model_position, 1)).xyz;
	float3 view_position = mul(MV, float4(model_position, 1)).xyz;
	float4 cs_position = mul(MVP, float4(model_position, 1));

	float3x3 linear_transform = adjoint(M);
	float3 world_normal = normalize(mul(linear_transform, model_normal));
	float3 world_tangent = normalize(mul(linear_transform, model_tangent));

	float3 bitangent = normalize(cross(world_normal, world_tangent));
	if (dot(world_normal, bitangent) < 0) bitangent = normalize(bitangent * -1);

    float3x3 TBN = transpose(float3x3(world_tangent, bitangent, world_normal));

	Frag_Input output;
	output.cs_position = cs_position;
	output.os_position = model_position;
	output.ws_position = world_position;
	output.vs_position = view_position;
	output.ts_light_dir = mul(TBN, light_dir);
	output.ts_position = mul(TBN, world_position);
	output.ts_view_pos = mul(TBN, view_pos);
	output.tex_coord = input.tex_coord;
	output.colour = instance.diffuse_colour;
	output.feature_flags = instance.feature_flags;
	return output;
}

#endif

#ifdef FRAGMENT_SHADER

cbuffer Constant_Buffer : register(b0, space3) {
	float3 light_colour;
	float pad2;
	row_major float4x4 light_matrix;
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
	return depth - bias > shadow_sample.r ? 1.0 : 0.0;
}

float4 fragment_main(Frag_Input input): SV_Target {
	if (input.feature_flags.x > 0.0) {
		return float4(input.colour);
	}

	float2 tex_coord = input.tex_coord * input.material_params.w;

	float3 diffuse = diffuse_map.Sample(diffuse_sampler, tex_coord).xyz;
	float3 ts_normal = normal_map.Sample(normal_sampler, tex_coord).xyz;
	float4 rmaoh = rmaoh_map.Sample(rmaoh_sampler, input.tex_coord);

	diffuse = input.colour.xyz * pow(diffuse, float3(2.2, 2.2, 2.2));

	ts_normal = ts_normal * 2 - 1;
	ts_normal.x = -ts_normal.x;
	ts_normal = normalize(ts_normal);

	rmaoh = float4(rmaoh.xyz * input.material_params.xyz, rmaoh.w);

	Material material;
	material.roughness = clamp(rmaoh.x, 0.0, 1.0);
	material.metallic = clamp(rmaoh.y, 0.0, 1.0);
	material.ambient_occlusion = clamp(rmaoh.z, 0.0, 1.0);

	float4 ls_position = mul(light_matrix, float4(input.ws_position, 1));
	float3 shadow_coord = ls_position.xyz / ls_position.w;
	shadow_coord = shadow_coord * 0.5 + 0.5;
	shadow_coord.z = 1.0 - shadow_coord.z;

	float2 shadow_tex_coord = shadow_coord.xy;
	shadow_tex_coord.y = 1 - shadow_tex_coord.y;

	float bias = 0.005;
	float shadow = shadow_calculation(shadow_coord.z, shadow_tex_coord, bias);

	float3 colour = lighting_directional(shadow, input.ts_position, ts_normal, input.ts_view_pos, input.ts_light_dir, diffuse, material, light_colour);

	if (frag_debug_mode == 1) {
		//colour = float3(shadow_coord.z, 0, 0);
		colour = float3(shadow, 0, 0);
	}

	return float4(colour, input.colour.w);
}

#endif