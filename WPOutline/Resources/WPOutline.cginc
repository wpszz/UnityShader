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

inline half3 OutlineWeight(float4 screenPos, half3 albedo, float kernelX, float kernelY, float kernelW)
{
	screenPos.x += WP_DepthNormalMap_TexelSize.x * kernelX * WP_OutlineParams.w;
	screenPos.y += WP_DepthNormalMap_TexelSize.y * kernelY * WP_OutlineParams.w;
	return Outline(screenPos, albedo) * kernelW;
}

inline half3 OutlineOutput(float4 screenPos, half3 albedo)
{
	half3 color = half3(0, 0, 0);
	if (WP_OutlineParams.y < 1)
		color = Outline(screenPos, albedo);
	else /*if (WP_OutlineParams.y < 2)*/
	{
		color += OutlineWeight(screenPos, albedo, -1.0, 0.0, 0.3);
		color += OutlineWeight(screenPos, albedo, 0.0, 0.0, 0.4);
		color += OutlineWeight(screenPos, albedo, 1.0, 0.0, 0.3);
	}
	/*
	else if (WP_OutlineParams.y < 3)
	{
		color += OutlineWeight(screenPos, albedo, -1.0, 0.0, 0.15);
		color += OutlineWeight(screenPos, albedo, 0.0, -1.0, 0.15);
		color += OutlineWeight(screenPos, albedo, 0.0, 0.0, 0.4);
		color += OutlineWeight(screenPos, albedo, 1.0, 0.0, 0.15);
		color += OutlineWeight(screenPos, albedo, 0.0, 1.0, 0.15);
	}
	else
	{
		color += OutlineWeight(screenPos, albedo, -1.0, -1.0, 0.075);
		color += OutlineWeight(screenPos, albedo, 0.0, -1.0, 0.1);
		color += OutlineWeight(screenPos, albedo, 1.0, -1.0, 0.075);
		color += OutlineWeight(screenPos, albedo, -1.0, 0.0, 0.1);
		color += OutlineWeight(screenPos, albedo, 0.0, 0.0, 0.3);
		color += OutlineWeight(screenPos, albedo, 1.0, 0.0, 0.1);
		color += OutlineWeight(screenPos, albedo, -1.0, 1.0, 0.075);
		color += OutlineWeight(screenPos, albedo, 0.0, 1.0, 0.1);
		color += OutlineWeight(screenPos, albedo, 1.0, 1.0, 0.075);
	}
	*/
	return color;
}

#define WP_OUTLINE_INPUT float4 wp_screenPos;
#define WP_OUTLINE_VERT(v, o) float4 pos = mul(UNITY_MATRIX_MVP, v.vertex); \
	o.wp_screenPos = ComputeScreenPos(pos); \
	o.wp_screenPos.z = COMPUTE_DEPTH_01;
#define WP_OUTLINE_SURF(IN, c) c.rgb = OutlineOutput(IN.wp_screenPos, c.rgb); 

#endif
