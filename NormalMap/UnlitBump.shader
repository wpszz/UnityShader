Shader "WP/UnlitBump"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_NormalMap("NormalMap", 2D) = "bump" {}
		_LightDir("LightDir", Color) = (1.0,1.0,0.0,1.0)
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
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NormalMap;
			fixed4 _LightDir;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

				float3 normal = UnpackNormal(tex2D(_NormalMap, i.uv)).rgb;

				float lambert = saturate(dot(normal, normalize(_LightDir.xyz)));
				lambert = lambert * 0.5 + 0.5;

				fixed3 diffuse = lambert * fixed3(1, 1, 1);

				col.rgb = col.rgb * diffuse;

				return col;
			}
			ENDCG
		}
	}
}
