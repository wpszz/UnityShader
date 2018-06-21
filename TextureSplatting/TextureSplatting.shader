Shader "WP/TextureSplatting"
{
	Properties
	{
		_MainTex ("Splat Texture", 2D) = "white" {}
		[NoScaleOffset]_LayerTex1("Layer1 Texture", 2D) = "white" {}
		[NoScaleOffset]_LayerTex2("Layer2 Texture", 2D) = "white" {}
		[NoScaleOffset]_LayerTex3("Layer3 Texture", 2D) = "white" {}
		[NoScaleOffset]_LayerTex4("Layer4 Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uvSplat : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _LayerTex1, _LayerTex2, _LayerTex3, _LayerTex4;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uvSplat = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 splat = tex2D(_MainTex, i.uvSplat);
				fixed3 layer1 = tex2D(_LayerTex1, i.uv) * splat.r;
				fixed3 layer2 = tex2D(_LayerTex2, i.uv) * splat.g;
				fixed3 layer3 = tex2D(_LayerTex3, i.uv) * splat.b;
				fixed3 layer4 = tex2D(_LayerTex4, i.uv) * (1 - splat.r - splat.g - splat.b);
				splat.rgb = layer1 + layer2 + layer3 + layer4;
				return splat;
			}
			ENDCG
		}
	}
}
