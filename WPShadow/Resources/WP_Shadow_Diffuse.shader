Shader "WP/Shadow/Diffuse"
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
		#include "WPShadow.cginc"
		#pragma surface surf Lambert vertex:vert exclude_path:prepass noforwardadd novertexlights //noshadow
		#pragma exclude_renderers xbox360 ps3
		#pragma skip_variants UNITY_HDR_ON
		//#pragma multi_compile __ WP_SHADOW_AA

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;

			WP_SHADOW_INPUT
		};

		void vert(inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);

			WP_SHADOW_VERT(v, o);
		}

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);

			o.Albedo = c.rgb;
			o.Alpha = c.a;

			WP_SHADOW_SURF(IN, o.Albedo);
		}
		ENDCG
	}
	//Fallback "Mobile/VertexLit"
}
