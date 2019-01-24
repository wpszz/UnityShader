Shader "WP/Noise/Vertex"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
		_Amount("Noise amount", Range(0, 1)) = .02
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
			#pragma target 2.0
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _Amount;

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

				float rx = noise(random(v.vertex.yz));
				float ry = noise(random(v.vertex.xz));
				float rz = noise(random(v.vertex.xy));;
				v.vertex.xyz += normalize(float3(rx, ry, rz)) * _Amount;

				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;

				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : COLOR
			{
				fixed4 col = tex2D(_MainTex, i.uv);

				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}

			ENDCG
		}
	}
}
