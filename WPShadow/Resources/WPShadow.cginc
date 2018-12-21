#ifndef WP_SHADOW_INCLUDED
#define WP_SHADOW_INCLUDED

uniform sampler2D WP_ShadowMap;
uniform float4 WP_ShadowMap_TexelSize;
uniform float4x4 WP_MatrixVPC;
uniform float4x4 WP_MatrixV;
uniform float WP_AA;
uniform float WP_Identity;

inline float SampleDepth(float2 uv)
{
	float depth = tex2D(WP_ShadowMap, uv).r;
	return depth;
}

inline float ClipShadowDepth(float shadowDepth, float3 uvz)
{
	return step(shadowDepth, uvz.z) * step(shadowDepth, 0.9)
		* step(0, uvz.x) * step(0, uvz.y) * step(uvz.x, 1) * step(uvz.y, 1);
}

inline float GaussianShadowDepth(float3 uvz, float kernelX, float kernelY, float kernelW) {
	float shadowDepth = SampleDepth(float2(uvz.x + WP_ShadowMap_TexelSize.x * kernelX, uvz.y + WP_ShadowMap_TexelSize.y * kernelY));
	return ClipShadowDepth(shadowDepth, uvz) * kernelW;
}

inline float WPShadowAtten(float3 uvz) {
	float shadowDepth = 0;
	if (WP_AA > 0)
	{
		/* simple anti-aliasing */
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
	else
		shadowDepth = ClipShadowDepth(SampleDepth(uvz.xy), uvz);
	return 1 - WP_Identity * shadowDepth;
}

inline fixed4 LightingT4M(SurfaceOutput s, fixed3 lightDir, fixed atten)
{
	fixed diff = dot(s.Normal, lightDir);
	fixed4 c;
	c.rgb = s.Albedo * _LightColor0.rgb * (diff * atten * 2);
	c.a = 0.0;
	return c;
}

#define WP_SHADOW_INPUT float3 wp_uvz;
#define WP_SHADOW_VERT(v, o) float cullZ = mul((float3x3)WP_MatrixV, mul((float3x3)unity_ObjectToWorld, v.normal)).z; \
	o.wp_uvz = mul(WP_MatrixVPC, mul(unity_ObjectToWorld, v.vertex)).xyz; \
	o.wp_uvz.z = o.wp_uvz.z * 0.5 + 0.5; \
	o.wp_uvz *= step(0, cullZ);
#define WP_SHADOW_SURF(IN, c) c.rgb *= WPShadowAtten(IN.wp_uvz); 

#endif
