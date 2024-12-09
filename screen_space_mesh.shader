#include "shared.shader"

struct Frag_Input {
	float4 ndc_position: SV_Position;
	float2 tex_coord: TEXCOORD0;
};

#ifdef VERTEX_SHADER

struct Vertex_Input {
	float3 position: POSITION;
	float2 tex_coord: TEXCOORD0;
};

cbuffer Constant_Buffer : register(b0, space1) {
	row_major float4x4 projection;
};

Frag_Input vertex_main(Vertex_Input input) {
	float4 ndc_position = mul(projection, float4(input.position, 1));

	Frag_Input output;
	output.tex_coord = input.tex_coord;
	output.ndc_position = ndc_position;
	return output;
}

#endif

#ifdef FRAGMENT_SHADER

Texture2D<float4> diffuse_texture: register(t0, space2);
SamplerState diffuse_sampler: register(s0, space2);

float4 fragment_main(Frag_Input input): SV_Target {
	float sample = diffuse_texture.Sample(diffuse_sampler, input.tex_coord).r;
	float4 colour = float4(input.tex_coord.xy, 0, 0) * float4(sample, sample, sample, 1);
	return colour;
}

#endif