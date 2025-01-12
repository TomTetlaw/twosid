#include "shared.hlsl"

struct Frag_Input {
	float4 ndc_position: SV_Position;
	float2 tex_coord: TEXCOORD0;
	float4 colour: TEXCOORD1;
};

struct Vertex_Input {
	float3 position: POSITION;
	float2 tex_coord: TEXCOORD0;
};

cbuffer Constant_Buffer : register(b0, space1) {
	row_major float4x4 projection;
};

struct Instance_Data {
	float4 position_size;
	float4 colour;
	float4 tex_coord;
};

StructuredBuffer<Instance_Data> instance_data: register(t0, space0);

Frag_Input vertex_main(Vertex_Input input, uint instance_id: SV_InstanceId) {
	Instance_Data instance = instance_data[instance_id];

	float2 position = instance.position_size.xy + input.position.xy*instance.position_size.zw;

	float2 tex_coord = instance.tex_coord.xy + instance.tex_coord.zw*input.tex_coord;

	float4 model_position = float4(position.x, position.y, 0, 1);
	float4 ndc_position = mul(projection, model_position);

	Frag_Input output;
	output.ndc_position = ndc_position;
	output.tex_coord = tex_coord;
	output.colour = instance.colour;
	return output;
}

Texture2D<float4> diffuse_texture: register(t0, space2);
SamplerState diffuse_sampler: register(s0, space2);

float4 fragment_main(Frag_Input input): SV_Target {
	float4 sample = diffuse_texture.Sample(diffuse_sampler, input.tex_coord);
	return sample * input.colour;
}