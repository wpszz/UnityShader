Shader "WP/Noise/Base"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
		_Scale("Noise scale", Range(1, 100)) = 10
	}

	CGINCLUDE
	#include "WPNoise.cginc"
	ENDCG

	SubShader
	{
		Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
		Cull Back

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _Scale;

			struct appdata_t
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;

				UNITY_FOG_COORDS(1)
			};

			v2f vert(appdata_t v)
			{
				v2f o;

				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;

				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : COLOR
			{
				fixed4 col = tex2D(_MainTex, i.uv);

				float x = noise(i.uv * _Scale);
				col *= x;

				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}

			ENDCG
		}
	}
}
