Shader "WP/Outline/DepthNormal"
{
	Properties
	{
	}
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

			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 vertex : POSITION;
				float2 depthNormal : TEXCOORD0;
			};

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.depthNormal.x = COMPUTE_DEPTH_01;
				float3 worldViewDir = _WorldSpaceCameraPos.xyz - o.vertex;
				float3 worldNormal = mul((float3x3)UNITY_MATRIX_M, v.normal);
				o.depthNormal.y = saturate(dot(normalize(worldViewDir), normalize(worldNormal)));
				return o;
			}

			half4 frag(v2f i) : COLOR
			{
				return half4(EncodeFloatRG(i.depthNormal.x), EncodeFloatRG(i.depthNormal.y));
			}
			ENDCG
		}
	}
}
