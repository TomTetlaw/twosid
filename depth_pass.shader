#include "shared.shader"

#ifdef VERTEX_SHADER

cbuffer Constant_Buffer : register(b0, space1) {
	row_major matrix world;
	row_major matrix light_matrix;
};

struct Vertex_Input {
	float3 position: POSITION;
	float3 bone_weights : TEXCOORD0;
	short4 bone_ids : TEXCOORD1;
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

float4 vertex_main(Vertex_Input input): SV_Position {
	float3 model_position = skinning_calculation(input.position, input.bone_weights, input.bone_ids);
	matrix MVP = mul(light_matrix, world);
	return mul(MVP, float4(model_position, 1));
}

#endif

#ifdef FRAGMENT_SHADER

float4 fragment_main() : SV_Target {
	return float4(0, 0, 0, 0);
}

#endif