#include "shared.shader"

struct Frag_Input {
	float4 ndc_position: SV_Position;
	float3 object_space_position: TEXCOORD0;
	float3 view_space_position: TEXCOORD1;
	float3 world_space_position: TEXCOORD2;
	float4 light_space_position0: TEXCOORD3;
	float4 light_space_position1: TEXCOORD4;
	float4 light_space_position2: TEXCOORD5;
	float2 tex_coord: TEXCOORD6;
	float3 normal: TEXCOORD7;
	float3 colour: TEXCOORD8;
};

#ifdef VERTEX_SHADER

cbuffer Constant_Buffer : register(b0, space1) {
	row_major matrix world;
	row_major matrix view;
	row_major matrix projection;
	row_major matrix light_matrix0;
	row_major matrix light_matrix1;
	row_major matrix light_matrix2;
	float3 diffuse_colour;
	float pad;
};

struct Vertex_Input {
	float3 position: POSITION;
	float2 tex_coord: TEXCOORD0;
    float3 normal: TEXCOORD1;
	float3 bone_weights: TEXCOORD2;
    short4 bone_ids: TEXCOORD3;
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

	matrix M = world;
	matrix MV = mul(view, world);
	matrix MVP = mul(projection, mul(view, world));

	float4 world_position = mul(M, float4(model_position, 1));
	float4 view_position = mul(MV, float4(model_position, 1));
	float4 ndc_position = mul(MVP, float4(model_position, 1));

	Frag_Input output;
	output.ndc_position = ndc_position;
	output.object_space_position = model_position;
	output.world_space_position = world_position.xyz;
	output.view_space_position = view_position.xyz;
	output.light_space_position0 = mul(light_matrix0, float4(output.view_space_position, 1));
	output.light_space_position1 = mul(light_matrix1, float4(output.view_space_position, 1));
	output.light_space_position2 = mul(light_matrix2, float4(output.view_space_position, 1));
	output.tex_coord = input.tex_coord;
	output.normal = model_normal;
	output.colour = diffuse_colour;
	return output;
}

#endif

#ifdef FRAGMENT_SHADER

cbuffer Constant_Buffer : register(b0, space3) {
	float3 camera_position;
	float pad0;
	float3 light_dir;
	float pad1;
	float3 light_colour;
	float pad2;
	float3 material_params;
	float pad3;
	float3 depth_planes;
	float pad4;
};

Texture2D shadow_map0: register(t0, space2);
Texture2D shadow_map1: register(t1, space2);
Texture2D shadow_map2: register(t2, space2);
Texture2D diffuse_map: register(t3, space2);
Texture2D normal_map: register(t4, space2);
Texture2D rmaoh_map: register(t5, space2);

SamplerState shadow_sampler0: register(s0, space2);
SamplerState shadow_sampler1: register(s1, space2);
SamplerState shadow_sampler2: register(s2, space2);
SamplerState diffuse_sampler: register(s3, space2);
SamplerState normal_sampler: register(s4, space2);
SamplerState rmaoh_sampler: register(s5, space2);

float sample_shadow_map(float3 shadow_coord, Texture2D shadow_map, SamplerState shadow_sampler, float bias) {
	if (shadow_coord.z > 1) return 0;
	
	uint w, h;
	shadow_map.GetDimensions(w, h);
	float2 texel_size = 1.0 / float2(w, h);

	float shadow = 0;

	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			float4 pcf_depth = shadow_map.Sample(shadow_sampler, shadow_coord.xy + float2(x, y) * texel_size);
			shadow += (shadow_coord.z - bias) > pcf_depth.r ? 1.0 : 0.0;
		}
	}

	shadow /= 9.0;

	return shadow;
}

float4 fragment_main(Frag_Input input): SV_Target {
	float2 tex_coord = input.tex_coord * material_params.x;
	
	float3 diffuse = diffuse_map.Sample(diffuse_sampler, tex_coord).xyz;	
	diffuse = input.colour * pow(diffuse, float3(2.2, 2.2, 2.2));

	float3 normal = normal_map.Sample(normal_sampler, tex_coord).xyz * 2.0 - 1.0;
	normal = normalize(normal);
	normal = unpack_blend_normal(camera_position, input.object_space_position, tex_coord, input.normal, normal);

	float bias = max(0.05 * (1.0 - dot(normal, light_dir)), 0.005);
	float shadow = 0;

	float3 debug;

	float depth = abs(input.view_space_position.x);
	if (depth < depth_planes.x) {
		float4 light_space_position = input.light_space_position0;
		float3 shadow_coord = shadow_projection_coord(light_space_position);
		bias *= 1 / (depth_planes.x * 0.5);
		shadow = sample_shadow_map(shadow_coord, shadow_map0, shadow_sampler0, bias);
		debug = float3(1, 0, shadow);
	} else if (depth < depth_planes.y) {
		float4 light_space_position = input.light_space_position1;
		float3 shadow_coord = shadow_projection_coord(light_space_position);
		bias *= 1 / (depth_planes.y * 0.5);
		shadow = sample_shadow_map(shadow_coord, shadow_map1, shadow_sampler1, bias);
		debug = float3(0, 1, shadow);
	} else {
		float4 light_space_position = input.light_space_position2;
		float3 shadow_coord = shadow_projection_coord(light_space_position);
		bias *= 1 / (1000.0 * 0.5);
		shadow = sample_shadow_map(shadow_coord, shadow_map2, shadow_sampler2, bias);
		debug = float3(1, 1, shadow);
	}

	float4 rmaoh = rmaoh_map.Sample(rmaoh_sampler, tex_coord);

	Material material;
	material.roughness = 1 * rmaoh.r;
	material.metallic = 1 * rmaoh.g;
	material.ambient_occlusion = 1 * rmaoh.b;

	float3 colour = lighting_directional(shadow, input.world_space_position, normal, diffuse, material, camera_position, light_dir, light_colour);

	//float d = (input.ndc_position.z / input.ndc_position.w);
	//colour = debug;
	//colour = float3(d, 0, 0);
	//colour = float3(1, 1, 1);
	//colour = float3(d,0,0);
	//colour = diffuse;

	return float4(colour, 1);
}

#endif