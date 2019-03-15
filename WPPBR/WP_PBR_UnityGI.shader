Shader "WP/PBR/UnityGI" 
{
	Properties 
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpMap ("Normalmap", 2D) = "bump" {}
		[Gamma]_Metallic ("Metallic", Range(0,1)) = 0.0		
		_Smoothness("Smoothness", Range(0,1)) = 0.5
		_BRDFLut("BRDF Lut", 2D) = "white" {}
	}

	SubShader 
	{
		Tags { "RenderType"="Opaque" }		
		LOD 200
		
		CGINCLUDE
		#define WP_UNITY_GI 1

		ENDCG

		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert
			#pragma fragment frag

			#include "WP_PBR.cginc"

			ENDCG
		}
	}
	FallBack "Diffuse"
}
