#include "shared.hlsl"

struct Frag_Input {
	float4 ndc_position: SV_Position;
	float2 tex_coord: TEXCOORD0;
	float4 colour: TEXCOORD1;
	nointerpolation float4 params: TEXCOORD2;
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
	float4 params;
};

StructuredBuffer<Instance_Data> instance_data: register(t0, space0);

Frag_Input vertex_main(Vertex_Input input, uint instance_id: SV_InstanceId) {
	Instance_Data instance = instance_data[instance_id];

	float2 position = instance.position_size.xy + input.position.xy*instance.position_size.zw;

	float2 tex_coord = instance.tex_coord.xy + input.tex_coord*instance.tex_coord.zw;

	float4 model_position = float4(position.x, position.y, 0, 1);
	float4 ndc_position = mul(projection, model_position);

	Frag_Input output;
	output.ndc_position = ndc_position;
	output.tex_coord = tex_coord;
	output.colour = instance.colour;
	output.params = instance.params;
	return output;
}

Texture2D<float4> diffuse_texture: register(t0, space2);
SamplerState diffuse_sampler: register(s0, space2);

float2 fwidth(float2 t) {
	return float2(
		ddx_fine(abs(t.x)) + ddy_fine(abs(t.x)),
		ddx_fine(abs(t.y)) + ddy_fine(abs(t.y))
	);
}

float median(float3 rgb) {
	return max(min(rgb.r, rgb.g), min(max(rgb.r, rgb.g), rgb.b));
}

float screen_range(float2 tex_coord, float4 params) {
	int w, h;
	diffuse_texture.GetDimensions(w, h);
	float2 dim = float2(w, h);

	float2 unit_range = float2(params.z, params.w) / dim;
	float2 screen_size = float2(1, 1) / fwidth(tex_coord);
	return max(0.5*dot(unit_range, screen_size), 1.0);
}

float contour(float2 tex_coord, float sdf, float4 params) {
	float width = screen_range(tex_coord, params);
	float e = width * (sdf - 0.5) + 0.5;
	return smoothstep(0.0, 1.0, e);
}

float sdf_sample(float2 tex_coord, float4 params) {
	float3 msdf = diffuse_texture.Sample(diffuse_sampler, tex_coord).rgb;
	float sdf = median(msdf);
	return contour(tex_coord, sdf, params);
}

float4 fragment_main(Frag_Input input): SV_Target {
	float2 tex_coord = input.tex_coord;
	float4 sample = diffuse_texture.Sample(diffuse_sampler, input.tex_coord);
 
	float sdf = sdf_sample(tex_coord, input.params);
	float2 d = 0.354 * (ddx(tex_coord) + ddy(tex_coord));
	float4 box = float4(tex_coord - d, tex_coord + d);
	float sum = sdf_sample(box.xy, input.params) + 
				sdf_sample(box.zw, input.params) + 
				sdf_sample(box.xw, input.params) +
				sdf_sample(box.zy, input.params);

	float opacity = (sdf + 0.5 * sum) / 3.0;
	return float4(input.colour.rgb, opacity);
}