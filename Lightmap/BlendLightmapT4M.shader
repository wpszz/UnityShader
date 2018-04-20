Shader "BlendLightmap/T4M 4 Textures for Mobile" 
{
	Properties 
	{
		_Splat0 ("Layer 1", 2D) = "white" {}
		_Splat1 ("Layer 2", 2D) = "white" {}
		_Splat2 ("Layer 3", 2D) = "white" {}
		_Splat3 ("Layer 4", 2D) = "white" {}
		_Control ("Control (RGBA)", 2D) = "white" {}
		_MainTex ("Never Used", 2D) = "white" {}
		_BlendTex ("Lightmap (RGB)", 2D) = "white" {}
		_BlendTex2 ("Lightmap2 (RGB)", 2D) = "white" {}
		_Blend ("Blend", Range(0.0,1.0)) = 0.5
	}
                
	SubShader 
	{
		Tags 
		{
		   "SplatCount" = "4"
		   "RenderType" = "Opaque"
		}

		Pass 
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _Control;
			sampler2D _Splat0,_Splat1,_Splat2,_Splat3;
			sampler2D _MainTex;
			sampler2D _BlendTex;
			sampler2D _BlendTex2;
			float _Blend;

			float4 _Control_ST;
			float4 _Splat0_ST;
			float4 _Splat1_ST;
			float4 _Splat2_ST;
			float4 _Splat3_ST;

			struct v2f 
			{
				float4 vertex : POSITION;
				float4 pack0 : TEXCOORD0; // _Control _Splat0
				float4 pack1 : TEXCOORD1; // _Splat1 _Splat2
				float2 pack2 : TEXCOORD2; // _Splat3
				float4 lmap : TEXCOORD4;
			};

			v2f vert (appdata_full v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.pack0.xy = TRANSFORM_TEX(v.texcoord, _Control);
				o.pack0.zw = TRANSFORM_TEX(v.texcoord, _Splat0);
				o.pack1.xy = TRANSFORM_TEX(v.texcoord, _Splat1);
			    o.pack1.zw = TRANSFORM_TEX(v.texcoord, _Splat2);
				o.pack2.xy = TRANSFORM_TEX(v.texcoord, _Splat3);
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				return o;
			}

			float4 frag (v2f i) : COLOR
			{
				float2 uv_Control = i.pack0.xy;
				float2 uv_Splat0 = i.pack0.zw;
				float2 uv_Splat1 = i.pack1.xy;
				float2 uv_Splat2 = i.pack1.zw;
				float2 uv_Splat3 = i.pack2.xy;

				fixed4 splat_control = tex2D (_Control, uv_Control).rgba;
		
				fixed3 lay1 = tex2D (_Splat0, uv_Splat0);
				fixed3 lay2 = tex2D (_Splat1, uv_Splat1);
				fixed3 lay3 = tex2D (_Splat2, uv_Splat2);
				fixed3 lay4 = tex2D (_Splat3, uv_Splat3);

				fixed3 lays = (lay1 * splat_control.r + lay2 * splat_control.g + lay3 * splat_control.b + lay4 * splat_control.a);

				float4 blendTex = UNITY_SAMPLE_TEX2D(_BlendTex, i.lmap.xy);
				float4 blendTex2 = UNITY_SAMPLE_TEX2D(_BlendTex2, i.lmap.xy);

				// test mode, blendTex as same as blendTex2, so make blendTex2 dark for show some different.
				blendTex2 *= blendTex2 * blendTex2;

				// use sin curve by unity internal time to control blend progress.
				_Blend = clamp(abs(_SinTime.y), 0, 1);

				float3 blendRet = DecodeLightmap(lerp(blendTex, blendTex2, _Blend));

				return float4(lays * blendRet, 0);
			}

			ENDCG 
		}
	}

	// Fallback to Diffuse
	Fallback "Diffuse"
}
