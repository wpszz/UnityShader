Shader "LayaAir3D/T4M" {
	Properties {
		_Splat0("Layer 1", 2D) = "white" {}
		_Splat1("Layer 2", 2D) = "white" {}
		_Splat2("Layer 3", 2D) = "white" {}
		_Control("Control (RGBA)", 2D) = "white" {}

		[HideInInspector]_MainTex("Never Used", 2D) = "white" {}
	}
	SubShader {		
		Tags { "SplatCount" = "3" "RenderType" = "Opaque" }
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON

			#include "UnityCG.cginc"
			#include "UnityPBSLighting.cginc"
			#include "AutoLight.cginc"

			#pragma vertex vert
			#pragma fragment frag

			sampler2D _Control;
			sampler2D _Splat0,_Splat1,_Splat2;

			float4 _Control_ST;
			float4 _Splat0_ST;
			float4 _Splat1_ST;
			float4 _Splat2_ST;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
#ifdef LIGHTMAP_ON
				float4 texcoord1: TEXCOORD1;
#endif
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 uv1: TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 worldNormal: TEXCOORD3;
				SHADOW_COORDS(4)
				UNITY_FOG_COORDS(5)
#ifdef LIGHTMAP_ON
				float2 lmap : TEXCOORD6;
#else
				half3 sh : TEXCOORD6;
#endif
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv.xy = TRANSFORM_TEX(v.texcoord, _Control);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _Splat0);
				o.uv1.xy = TRANSFORM_TEX(v.texcoord, _Splat1);
				o.uv1.zw = TRANSFORM_TEX(v.texcoord, _Splat2);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = worldPos;
				o.worldNormal = worldNormal;

				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o, o.pos);

#ifdef LIGHTMAP_ON
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#else
	#if UNITY_SHOULD_SAMPLE_SH
				o.sh = ShadeSH9(float4(worldNormal, 1.0));
	#else
				o.sh = 0.0;
	#endif
	#ifdef VERTEXLIGHT_ON
				o.sh += Shade4PointLights(
					unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
					unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
					unity_4LightAtten0, worldPos, worldNormal);
	#endif
#endif
				return o;
			}

			fixed4 frag(v2f i) : SV_Target{

				fixed3 albedo = 0;
				fixed3 splat_control = tex2D(_Control, i.uv.xy).rgb;
				fixed3 lay1 = tex2D(_Splat0, i.uv.zw);
				fixed3 lay2 = tex2D(_Splat1, i.uv1.xy);
				fixed3 lay3 = tex2D(_Splat2, i.uv1.zw);
				albedo.rgb = lay1 * splat_control.r + lay2 * splat_control.g + lay3 * splat_control.b;
				
				float3 worldPos = i.worldPos;

#ifndef USING_DIRECTIONAL_LIGHT
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
#else
				fixed3 lightDir = _WorldSpaceLightPos0.xyz;
#endif

				UNITY_LIGHT_ATTENUATION(atten, i, worldPos)

				fixed4 c = 0;

#ifdef LIGHTMAP_ON
				// Lightmap
				fixed4 lm = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lmap));
				c.rgb += albedo * lm;
#else
				// SH
				c.rgb += albedo * i.sh;
				// Diffuse
				c.rgb += albedo * _LightColor0.rgb * (dot(i.worldNormal, lightDir) * atten);
#endif

				UNITY_APPLY_FOG(i.fogCoord, c);
				UNITY_OPAQUE_ALPHA(c.a);
				return c;
			}

			ENDCG
		}
	} 
	FallBack "Diffuse"
}
