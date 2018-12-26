Shader "WP/Outline/Naive"
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
		uniform float4 WP_OutlineParams; // x: intensity y:power
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

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);

			o.Albedo = c.rgb;
			o.Alpha = c.a;

			o.Albedo.rgb = Outline(IN.wp_screenPos, o.Albedo.rgb);
		}
		ENDCG
	}
	//Fallback "Mobile/VertexLit"
}
