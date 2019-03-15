Shader "WP/PBR/Fur" 
{
	Properties 
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpMap ("Normalmap", 2D) = "bump" {}
		[Gamma]_Metallic ("Metallic", Range(0,1)) = 0.0		
		_Smoothness("Smoothness", Range(0,1)) = 0.5
		_BRDFLut("BRDF Lut", 2D) = "white" {}	

		[Space(20)]
		_FurLayerTex("Fur layer mask", 2D) = "white" {}
		_FurLength("Fur Length", Range(.0002, 1)) = .25
		_FurCutoffStart("Fur Alpha Cutoff start", Range(0,1)) = 0.5		// how "thick" they are at the start
		_FurCutoffEnd("Fur Alpha Cutoff end", Range(0,1)) = 0.5 // how thick they are at the end
		_FurEdgeFade("Fur Edge Fade", Range(0,1)) = 0.4
		_FurGravity("Fur Gravity Direction", Vector) = (0,-1,0,0)
		_FurGravityStrength("Fur Gravity Strength", Range(0,1)) = 0.25

		_SrcBlend("SrcBlend", Float) = 5.0
		_DstBlend("DstBlend", Float) = 10.0
		_ZWrite("ZWrite", Float) = 1.0
	}

	SubShader 
	{
		Tags { "RenderType"="Opaque" }		
		LOD 200

		Blend[_SrcBlend][_DstBlend]
		ZWrite[_ZWrite]

		CGINCLUDE
		#define WP_UNITY_GI 1

		#include "WP_PBR.cginc"

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

			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer01
			#pragma fragment frag_layer01
			VertexOutput vert_layer01(VertexInput v) { return vert_furBias(v, 0.05 * 1); }
			fixed4 frag_layer01(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 1); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer02
			#pragma fragment frag_layer02
			VertexOutput vert_layer02(VertexInput v) { return vert_furBias(v, 0.05 * 2); }
			fixed4 frag_layer02(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 2); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer03
			#pragma fragment frag_layer03
			VertexOutput vert_layer03(VertexInput v) { return vert_furBias(v, 0.05 * 3); }
			fixed4 frag_layer03(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 3); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer04
			#pragma fragment frag_layer04
			VertexOutput vert_layer04(VertexInput v) { return vert_furBias(v, 0.05 * 4); }
			fixed4 frag_layer04(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 4); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer05
			#pragma fragment frag_layer05
			VertexOutput vert_layer05(VertexInput v) { return vert_furBias(v, 0.05 * 5); }
			fixed4 frag_layer05(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 5); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer06
			#pragma fragment frag_layer06
			VertexOutput vert_layer06(VertexInput v) { return vert_furBias(v, 0.05 * 6); }
			fixed4 frag_layer06(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 6); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer07
			#pragma fragment frag_layer07
			VertexOutput vert_layer07(VertexInput v) { return vert_furBias(v, 0.05 * 7); }
			fixed4 frag_layer07(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 7); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer08
			#pragma fragment frag_layer08
			VertexOutput vert_layer08(VertexInput v) { return vert_furBias(v, 0.05 * 8); }
			fixed4 frag_layer08(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 8); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer09
			#pragma fragment frag_layer09
			VertexOutput vert_layer09(VertexInput v) { return vert_furBias(v, 0.05 * 9); }
			fixed4 frag_layer09(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 9); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer10
			#pragma fragment frag_layer10
			VertexOutput vert_layer10(VertexInput v) { return vert_furBias(v, 0.05 * 10); }
			fixed4 frag_layer10(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 10); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer11
			#pragma fragment frag_layer11
			VertexOutput vert_layer11(VertexInput v) { return vert_furBias(v, 0.05 * 11); }
			fixed4 frag_layer11(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 11); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer12
			#pragma fragment frag_layer12
			VertexOutput vert_layer12(VertexInput v) { return vert_furBias(v, 0.05 * 12); }
			fixed4 frag_layer12(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 12); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer13
			#pragma fragment frag_layer13
			VertexOutput vert_layer13(VertexInput v) { return vert_furBias(v, 0.05 * 13); }
			fixed4 frag_layer13(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 13); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer14
			#pragma fragment frag_layer14
			VertexOutput vert_layer14(VertexInput v) { return vert_furBias(v, 0.05 * 14); }
			fixed4 frag_layer14(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 14); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer15
			#pragma fragment frag_layer15
			VertexOutput vert_layer15(VertexInput v) { return vert_furBias(v, 0.05 * 15); }
			fixed4 frag_layer15(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 15); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer16
			#pragma fragment frag_layer16
			VertexOutput vert_layer16(VertexInput v) { return vert_furBias(v, 0.05 * 16); }
			fixed4 frag_layer16(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 16); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer17
			#pragma fragment frag_layer17
			VertexOutput vert_layer17(VertexInput v) { return vert_furBias(v, 0.05 * 17); }
			fixed4 frag_layer17(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 17); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer18
			#pragma fragment frag_layer18
			VertexOutput vert_layer18(VertexInput v) { return vert_furBias(v, 0.05 * 18); }
			fixed4 frag_layer18(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 18); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer19
			#pragma fragment frag_layer19
			VertexOutput vert_layer19(VertexInput v) { return vert_furBias(v, 0.05 * 19); }
			fixed4 frag_layer19(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 19); }
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer20
			#pragma fragment frag_layer20
			VertexOutput vert_layer20(VertexInput v) { return vert_furBias(v, 0.05 * 20); }
			fixed4 frag_layer20(VertexOutput IN) : SV_Target { return frag_furBias(IN, 0.05 * 20); }
			ENDCG
		}
	}
	FallBack "Diffuse"
}
