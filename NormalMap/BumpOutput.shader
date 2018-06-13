Shader "WP/BumpOutput"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_DeltaScale("DeltaScale", Range(0.01,1.0)) = 0.5
		_HeightScale("HeightScale", Range(0.01,1.0)) = 0.5
		_NormalScale("NormalScale", Range(-10,10)) = 1
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
			fixed4 _MainTex_TexelSize;
			float _DeltaScale;
			float _HeightScale;
			float _NormalScale;
			fixed4 _LightDir;

			float GetGrayColor(float3 color)
			{
				return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722;
			}

			float3 GetNormalByGray(float2 uv)
			{
				float2 deltaU = float2(_MainTex_TexelSize.x * _DeltaScale, 0);
				float h1_u = GetGrayColor(tex2D(_MainTex, uv - deltaU).rgb);
				float h2_u = GetGrayColor(tex2D(_MainTex, uv + deltaU).rgb);

				// float3 tangent_u = float3(1, 0, (h2_u - h1_u) / deltaU.x);
				float3 tangent_u = float3(deltaU.x, 0, (h2_u - h1_u) * _HeightScale);

				float2 deltaV = float2(0, _MainTex_TexelSize.y * _DeltaScale);
				float h1_v = GetGrayColor(tex2D(_MainTex, uv - deltaV).rgb);
				float h2_v = GetGrayColor(tex2D(_MainTex, uv + deltaV).rgb);

				// float3 tangent_v = float3(0, 1, (h2_v - h1_v) / deltaV.y);
				float3 tangent_v = float3(0, deltaV.y, (h2_v - h1_v) * _HeightScale);

				//float3 normal = normalize(cross(tangent_v, tangent_u));
				//normal.z *= -1;
				float3 normal = normalize(cross(tangent_u, tangent_v));

				// tangent Space (0, 0, 1) mapping to (0.5, 0.5, 1)
				normal = normal * 0.5 + 0.5;

				return normal;
			}

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

				float3 normal = GetNormalByGray(i.uv);

				// unpack normal (same work with Unity builtin UnpackNormal)
				normal = normal * 2 - 1;

				// scale normal
				normal.xy *= _NormalScale;
				normal = normalize(normal);

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
