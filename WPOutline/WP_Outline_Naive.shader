﻿Shader "WP/Outline/Naive"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 150

		CGPROGRAM

		#pragma surface surf Lambert vertex:vert exclude_path:prepass noforwardadd novertexlights addshadow //addshadow for depth texture 
		#pragma exclude_renderers xbox360 ps3
		#pragma skip_variants UNITY_HDR_ON

		sampler2D _MainTex;

		uniform sampler2D WP_DepthNormalMap;
		uniform float4 WP_DepthNormalMap_TexelSize;
		uniform float4 WP_OutlineParams; // x: intensity y:anti-aliasing z:power
		uniform half4 WP_OutlineColor;

		struct Input {
			float2 uv_MainTex;
			float4 wp_screenPos;
		};

		void vert(inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);

			float4 pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.wp_screenPos = ComputeScreenPos(pos);	// variable 'screenPos' is used internal
			o.wp_screenPos.z = COMPUTE_DEPTH_01;
		}

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
			else if (WP_OutlineParams.y < 2)
			{
				color += OutlineWeight(screenPos, albedo, -1.0, 0.0, 0.3);
				color += OutlineWeight(screenPos, albedo, 0.0, 0.0, 0.4);
				color += OutlineWeight(screenPos, albedo, 1.0, 0.0, 0.3);
			}
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
			return color;
		}

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);

			o.Albedo = c.rgb;
			o.Alpha = c.a;

			o.Albedo.rgb = OutlineOutput(IN.wp_screenPos, o.Albedo.rgb);
		}
		ENDCG
	}
	//Fallback "Mobile/VertexLit"
}
