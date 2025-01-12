#include "shared.hlsl"

struct Frag_Input {
	float4 cs_position: SV_Position;
	float4 colour: TEXCOORD0;
	float2 tex_coord: TEXCOORD1;
};

cbuffer Constant_Buffer : register(b0, space1) {
	row_major float4x4 view;
	row_major float4x4 projection;
};

struct Instance_Data {
	row_major float4x4 transform;
	float4 diffuse_colour;
};

StructuredBuffer<Instance_Data> instance_data: register(t0, space0);

struct Vertex_Input {
	float3 position: POSITION;
	float2 tex_coord: TEXCOORD0;
};

Frag_Input vertex_main(Vertex_Input input, uint instance_id: SV_InstanceId) {
	Instance_Data instance = instance_data[instance_id];

	float4x4 MVP = mul(projection, mul(view, instance.transform));
	float4 cs_position = mul(MVP, float4(input.position, 1));

	Frag_Input output;
	output.cs_position = cs_position;
	output.tex_coord = input.tex_coord;
	output.colour = instance.diffuse_colour;
	return output;
}

Texture2D diffuse_map: register(t0, space2);
SamplerState diffuse_sampler: register(s0, space2);

float4 fragment_main(Frag_Input input): SV_Target {
	return input.colour;

	float2 tex_coord = input.tex_coord;

	float3 diffuse = diffuse_map.Sample(diffuse_sampler, tex_coord).xyz;
	diffuse = input.colour.xyz * pow(diffuse, float3(2.2, 2.2, 2.2));

	float3 colour = input.colour.rgb * diffuse;
	return float4(colour, input.colour.w);
}