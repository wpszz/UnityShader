#ifndef WP_SHADOW_INCLUDED
#define WP_SHADOW_INCLUDED

#include "UnityCG.cginc"

uniform sampler2D WP_ShadowMap;
uniform float4 WP_ShadowMap_TexelSize;
uniform float4x4 WP_MatrixVPC;
uniform float4x4 WP_MatrixV;
uniform float4 WP_ControlParams;

inline float LightCameraDepth01(float z) {
	return saturate((z - WP_ControlParams.z) * WP_ControlParams.w);
}

inline float SampleDepth(float2 uv)
{
	return DecodeFloatRGBA(tex2D(WP_ShadowMap, uv));
}

inline float ClipShadowDepth(float shadowDepth, float3 uvz)
{
	float depth = LightCameraDepth01(uvz.z) - 0.0001;
	float2 inside = step(0, uvz.xy) * step(uvz.xy, 1);
	return step(shadowDepth, depth) * inside.x * inside.y;
}

inline float ShadowAtten(float3 uvz) {
	float shadow = 0;
	if (WP_ControlParams.y < 1)
		shadow = ClipShadowDepth(SampleDepth(uvz.xy), uvz);
	else
	{
		// PCF shadowmap filtering based on a 3x3 kernel (optimized with 4 taps)
		const float2 offset = float2(0.5, 0.5);
		float2 uv = (uvz.xy * WP_ShadowMap_TexelSize.zw) + offset;
		float2 base_uv = (floor(uv) - offset) * WP_ShadowMap_TexelSize.xy;
		float2 st = frac(uv);

		float2 uw = float2(3 - 2 * st.x, 1 + 2 * st.x);
		float2 u = float2((2 - st.x) / uw.x - 1, (st.x) / uw.y + 1);
		u *= WP_ShadowMap_TexelSize.x;

		float2 vw = float2(3 - 2 * st.y, 1 + 2 * st.y);
		float2 v = float2((2 - st.y) / vw.x - 1, (st.y) / vw.y + 1);
		v *= WP_ShadowMap_TexelSize.y;

		half sum = 0;
		sum += uw[0] * vw[0] * ClipShadowDepth(SampleDepth(base_uv + float2(u[0], v[0])), uvz);
		sum += uw[1] * vw[0] * ClipShadowDepth(SampleDepth(base_uv + float2(u[1], v[0])), uvz);
		sum += uw[0] * vw[1] * ClipShadowDepth(SampleDepth(base_uv + float2(u[0], v[1])), uvz);
		sum += uw[1] * vw[1] * ClipShadowDepth(SampleDepth(base_uv + float2(u[1], v[1])), uvz);

		shadow = sum / 16.0f;
	}
	return 1 - WP_ControlParams.x * shadow;
}

#define WP_SHADOW_INPUT float3 wp_uvz;
#define WP_SHADOW_VERT(v, o) o.wp_uvz = mul(WP_MatrixVPC, mul(unity_ObjectToWorld, v.vertex)).xyz; \
	o.wp_uvz.z = -mul(WP_MatrixV, mul(unity_ObjectToWorld, v.vertex)).z;
#define WP_SHADOW_SURF(IN, c) c.rgb *= ShadowAtten(IN.wp_uvz); 

#endif
