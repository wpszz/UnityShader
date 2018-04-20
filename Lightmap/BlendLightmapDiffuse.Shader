Shader "BlendLightmap/Diffuse"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlendTex ("Lightmap (RGB)", 2D) = "white" {}
		_BlendTex2 ("Lightmap2 (RGB)", 2D) = "white" {}
		_Blend ("Blend", Range(0.0,1.0)) = 0.5
	}

	SubShader
	{
		Cull Off
		Lighting Off
		ZWrite On

		Pass 
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _BlendTex;
			sampler2D _BlendTex2;
			float _Blend;

			struct appdata_t 
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float2 texcoord2 : TEXCOORD1;
			};

			struct v2f 
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float2 texcoord2 : TEXCOORD1;
			};

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = v.texcoord;
				// VF caculate lightmap uv
				o.texcoord2 = v.texcoord2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				return o;
			}

			float4 frag (v2f i) : COLOR
			{
				float4 mainTex = UNITY_SAMPLE_TEX2D(_MainTex, i.texcoord);
				float4 blendTex = UNITY_SAMPLE_TEX2D(_BlendTex, i.texcoord2);
				float4 blendTex2 = UNITY_SAMPLE_TEX2D(_BlendTex2, i.texcoord2);

				// test mode, blendTex as same as blendTex2, so make blendTex2 dark for show some different.
				blendTex2 *= blendTex2 * blendTex2;

				// use sin curve by unity internal time to control blend progress.
				_Blend = clamp(abs(_SinTime.y), 0, 1);

				float3 blendRet = DecodeLightmap(lerp(blendTex, blendTex2, _Blend));

				mainTex.rgb *= blendRet;
				return mainTex;
			}

			ENDCG 
		}
	} 

	// Fallback to Diffuse
	Fallback "Diffuse"
}