#ifndef WP_OUTLINE_INCLUDED
#define WP_OUTLINE_INCLUDED

uniform sampler2D WP_DepthNormalMap;
uniform float4 WP_DepthNormalMap_TexelSize;
uniform float4 WP_OutlineParams;
uniform half4 WP_OutlineColor;

inline half3 Outline(float4 screenPos, half3 albedo)
{
	half4 depthNormal = tex2Dproj(WP_DepthNormalMap, screenPos);
	float depth = DecodeFloatRG(depthNormal.xy);
	float rim = DecodeFloatRG(depthNormal.zw);
	float selfDepth = screenPos.z;
	half lerp = step(selfDepth, depth) * WP_OutlineParams.x;
	return albedo * (1 - lerp) + WP_OutlineColor.rgb * rim * lerp;
}

#define WP_OUTLINE_INPUT float4 wp_screenPos;
#define WP_OUTLINE_VERT(v, o) float4 pos = mul(UNITY_MATRIX_MVP, v.vertex); \
	o.wp_screenPos = ComputeScreenPos(pos); \
	o.wp_screenPos.z = COMPUTE_DEPTH_01;
#define WP_OUTLINE_SURF(IN, c) c.rgb = Outline(IN.wp_screenPos, c.rgb); 

#endif
