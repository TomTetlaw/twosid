#include "shared.shader"

#ifdef VERTEX_SHADER

cbuffer Constant_Buffer : register(b0, space1) {
	row_major float4x4 light_matrix;
	float4 time;
};

struct Vertex_Input {
	float3 position: POSITION;
	float3 bone_weights : TEXCOORD0;
	short4 bone_ids : TEXCOORD1;
};

struct Instance_Data {
	row_major float4x4 transform;
	float3 diffuse_colour;
	float pad0;
	float4 material_params;
};

struct Skinning_Data {
	row_major float4x4 transform;
};

StructuredBuffer<Skinning_Data> skinning_transforms: register(t0, space0);
StructuredBuffer<Instance_Data> instance_data: register(t1, space0);

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

float4 vertex_main(Vertex_Input input, uint instance_id: SV_InstanceId): SV_Position {
	Instance_Data instance = instance_data[instance_id];
	float3 model_position = skinning_calculation(input.position, input.bone_weights, input.bone_ids);

	float4x4 MVP = mul(light_matrix, instance.transform);
	return mul(MVP, float4(model_position, 1));
}

#endif

#ifdef FRAGMENT_SHADER

float fragment_main(float4 p: SV_Position) : SV_Depth {
	return 1.0 - (p.z * .5 + .5);
}

#endif