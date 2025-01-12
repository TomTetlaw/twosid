#include "shared.hlsl"

struct Frag_Input {
	float4 cs_position: SV_Position;
	float3 colour: TEXCOORD0;
};

cbuffer Constant_Buffer : register(b0, space1) {
	row_major float4x4 view;
	row_major float4x4 projection;
};

struct Instance_Data {
	row_major float4x4 transform;
	float3 diffuse_colour;
	float pad;
};

StructuredBuffer<Instance_Data> instance_data: register(t0, space0);

struct Vertex_Input {
	float3 position: POSITION;
};

Frag_Input vertex_main(Vertex_Input input, uint instance_id: SV_InstanceId) {
	Instance_Data instance = instance_data[instance_id];

	float4x4 M = instance.transform;
	float4x4 MV = mul(view, M);
	float4x4 MVP = mul(projection, mul(view, M));

	float4 cs_position = mul(MVP, float4(input.position, 1));

	Frag_Input output;
	output.cs_position = cs_position;
	output.colour = instance.diffuse_colour;
	return output;
}

float4 fragment_main(Frag_Input input): SV_Target {
	return float4(input.colour, 1);
}