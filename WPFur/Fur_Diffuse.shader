Shader "WP/Bur/Diffuse" 
{
	Properties 
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}

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
		#include "Fur.cginc"

		ENDCG

		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert_layer00
			#pragma fragment frag_layer00
			v2f vert_layer00(a2v v) { return vert(v, 0.05 * 0); }
			half4 frag_layer00(v2f i) : SV_Target { return frag(i, 0.05 * 0); }
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
			v2f vert_layer01(a2v v) { return vert(v, 0.05 * 1); }
			half4 frag_layer01(v2f i) : SV_Target { return frag(i, 0.05 * 1); }
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
			v2f vert_layer02(a2v v) { return vert(v, 0.05 * 2); }
			half4 frag_layer02(v2f i) : SV_Target { return frag(i, 0.05 * 2); }
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
			v2f vert_layer03(a2v v) { return vert(v, 0.05 * 3); }
			half4 frag_layer03(v2f i) : SV_Target { return frag(i, 0.05 * 3); }
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
			v2f vert_layer04(a2v v) { return vert(v, 0.05 * 4); }
			half4 frag_layer04(v2f i) : SV_Target { return frag(i, 0.05 * 4); }
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
			v2f vert_layer05(a2v v) { return vert(v, 0.05 * 5); }
			half4 frag_layer05(v2f i) : SV_Target { return frag(i, 0.05 * 5); }
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
			v2f vert_layer06(a2v v) { return vert(v, 0.05 * 6); }
			half4 frag_layer06(v2f i) : SV_Target { return frag(i, 0.05 * 6); }
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
			v2f vert_layer07(a2v v) { return vert(v, 0.05 * 7); }
			half4 frag_layer07(v2f i) : SV_Target { return frag(i, 0.05 * 7); }
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
			v2f vert_layer08(a2v v) { return vert(v, 0.05 * 8); }
			half4 frag_layer08(v2f i) : SV_Target { return frag(i, 0.05 * 8); }
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
			v2f vert_layer09(a2v v) { return vert(v, 0.05 * 9); }
			half4 frag_layer09(v2f i) : SV_Target { return frag(i, 0.05 * 9); }
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
			v2f vert_layer10(a2v v) { return vert(v, 0.05 * 10); }
			half4 frag_layer10(v2f i) : SV_Target { return frag(i, 0.05 * 10); }
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
			v2f vert_layer11(a2v v) { return vert(v, 0.05 * 11); }
			half4 frag_layer11(v2f i) : SV_Target { return frag(i, 0.05 * 11); }
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
			v2f vert_layer12(a2v v) { return vert(v, 0.05 * 12); }
			half4 frag_layer12(v2f i) : SV_Target { return frag(i, 0.05 * 12); }
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
			v2f vert_layer13(a2v v) { return vert(v, 0.05 * 13); }
			half4 frag_layer13(v2f i) : SV_Target { return frag(i, 0.05 * 13); }
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
			v2f vert_layer14(a2v v) { return vert(v, 0.05 * 14); }
			half4 frag_layer14(v2f i) : SV_Target { return frag(i, 0.05 * 14); }
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
			v2f vert_layer15(a2v v) { return vert(v, 0.05 * 15); }
			half4 frag_layer15(v2f i) : SV_Target { return frag(i, 0.05 * 15); }
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
			v2f vert_layer16(a2v v) { return vert(v, 0.05 * 16); }
			half4 frag_layer16(v2f i) : SV_Target { return frag(i, 0.05 * 16); }
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
			v2f vert_layer17(a2v v) { return vert(v, 0.05 * 17); }
			half4 frag_layer17(v2f i) : SV_Target { return frag(i, 0.05 * 17); }
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
			v2f vert_layer18(a2v v) { return vert(v, 0.05 * 18); }
			half4 frag_layer18(v2f i) : SV_Target { return frag(i, 0.05 * 18); }
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
			v2f vert_layer19(a2v v) { return vert(v, 0.05 * 19); }
			half4 frag_layer19(v2f i) : SV_Target { return frag(i, 0.05 * 19); }
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
			v2f vert_layer20(a2v v) { return vert(v, 0.05 * 20); }
			half4 frag_layer20(v2f i) : SV_Target { return frag(i, 0.05 * 20); }
			ENDCG
		}
	}
	FallBack "Diffuse"
}
