#ifndef WP_SHADOW_INCLUDED
#define WP_SHADOW_INCLUDED

uniform sampler2D WP_ShadowMap;
uniform float4 WP_ShadowMap_TexelSize;
uniform float4x4 WP_MatrixVPC;
uniform float4x4 WP_MatrixV;
uniform float4 WP_ControlParams;

inline float LightCameraDepth01(float z) {
	return (z - WP_ControlParams.z) * WP_ControlParams.w;
}

inline float SampleDepth(float2 uv)
{
	float depth = tex2D(WP_ShadowMap, uv).r;
	return depth;
}

inline float ClipShadowDepth(float shadowDepth, float3 uvz)
{
	float depth = LightCameraDepth01(uvz.z);
	return step(shadowDepth, depth) * step(0.001, shadowDepth)
		* step(0, uvz.x) * step(0, uvz.y) * step(uvz.x, 1) * step(uvz, 1);
}

inline float GaussianShadowDepth(float3 uvz, float kernelX, float kernelY, float kernelW) {
	float shadowDepth = SampleDepth(float2(uvz.x + WP_ShadowMap_TexelSize.x * kernelX, uvz.y + WP_ShadowMap_TexelSize.y * kernelY));
	return ClipShadowDepth(shadowDepth, uvz) * kernelW;
}

inline float ShadowAtten(float3 uvz) {
	float shadowDepth = 0;
	if (WP_ControlParams.y < 1)
		shadowDepth = ClipShadowDepth(SampleDepth(uvz.xy), uvz);
	else if (WP_ControlParams.y < 2)
	{
		shadowDepth += GaussianShadowDepth(uvz, -1.0, 0.0, 0.3);
		shadowDepth += GaussianShadowDepth(uvz, 0.0, 0.0, 0.4);
		shadowDepth += GaussianShadowDepth(uvz, 1.0, 0.0, 0.3);
	}
	else if (WP_ControlParams.y < 3)
	{
		shadowDepth += GaussianShadowDepth(uvz, -1.0, 0.0, 0.15);
		shadowDepth += GaussianShadowDepth(uvz, 0.0, -1.0, 0.15);
		shadowDepth += GaussianShadowDepth(uvz, 0.0, 0.0, 0.4);
		shadowDepth += GaussianShadowDepth(uvz, 1.0, 0.0, 0.15);
		shadowDepth += GaussianShadowDepth(uvz, 0.0, 1.0, 0.15);
	}
	else
	{
		shadowDepth += GaussianShadowDepth(uvz, -1.0, -1.0, 0.0585);
		shadowDepth += GaussianShadowDepth(uvz, 0.0, -1.0, 0.0965);
		shadowDepth += GaussianShadowDepth(uvz, 1.0, -1.0, 0.0585);
		shadowDepth += GaussianShadowDepth(uvz, -1.0, 0.0, 0.0965);
		shadowDepth += GaussianShadowDepth(uvz, 0.0, 0.0, 0.1529);
		shadowDepth += GaussianShadowDepth(uvz, 1.0, 0.0, 0.0965);
		shadowDepth += GaussianShadowDepth(uvz, -1.0, 1.0, 0.0585);
		shadowDepth += GaussianShadowDepth(uvz, 0.0, 1.0, 0.0965);
		shadowDepth += GaussianShadowDepth(uvz, 1.0, 1.0, 0.0585);
	}
	return 1 - WP_ControlParams.x * shadowDepth;
}

#define WP_SHADOW_INPUT float3 wp_uvz;
#define WP_SHADOW_VERT(v, o) o.wp_uvz = mul(WP_MatrixVPC, mul(unity_ObjectToWorld, v.vertex)).xyz; \
	o.wp_uvz.z = -mul(WP_MatrixV, mul(unity_ObjectToWorld, v.vertex)).z;
#define WP_SHADOW_SURF(IN, c) c.rgb *= ShadowAtten(IN.wp_uvz); 

#endif
