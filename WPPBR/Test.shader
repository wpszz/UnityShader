Shader "WP/PBR/Test" 
{
	Properties 
	{

	}

	SubShader 
	{
		Tags { "RenderType"="Opaque" }		
		LOD 200
		
		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityStandardBRDF.cginc"

			struct a2v
			{
				fixed4 vertex : POSITION;
				fixed3 normal : NORMAL;
				fixed4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				fixed4 pos : SV_POSITION;
				fixed2 uv : TEXCOORD0;
			};


			v2f vert(a2v v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.texcoord.xy;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half4 c = tex2D(unity_NHxRoughness, i.uv);
				return c;
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}
