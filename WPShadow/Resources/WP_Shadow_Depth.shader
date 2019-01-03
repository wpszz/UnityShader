Shader "WP/Shadow/Depth"
{
	Properties
	{
	}

	CGINCLUDE
	#include "WPShadow.cginc"
	ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Cull Back
		ZWrite On
		Fog { Mode Off }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			//#include "WPShadow.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
			};

			struct v2f {
				float4 vertex : POSITION;
				float2 depth : TEXCOORD0;
			};

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.depth = -mul(UNITY_MATRIX_MV, v.vertex).z;
				return o;
			}

			fixed4 frag(v2f i) : COLOR
			{
				return EncodeFloatRGBA(LightCameraDepth01(i.depth.x));
			}
			ENDCG
		}
	}
}
