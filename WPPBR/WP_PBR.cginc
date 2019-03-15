#ifndef WP_PBR_INCLUDED
#define WP_PBR_INCLUDED

#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

struct VertexInput {
	float4 vertex : POSITION;
	float4 tangent : TANGENT;
	float3 normal : NORMAL;
	float4 texcoord : TEXCOORD0;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput
{
	float4 pos		: SV_POSITION;
	float4 tex		: TEXCOORD0;
	float4 tSpace0	: TEXCOORD1;
	float4 tSpace1	: TEXCOORD2;
	float4 tSpace2	: TEXCOORD3;

	SHADOW_COORDS(4)
	UNITY_FOG_COORDS_PACKED(5, half4) // x: fogCoord, yzw: reflectVec

	UNITY_VERTEX_INPUT_INSTANCE_ID

#if WP_UNITY_GI
	half3 sh : TEXCOORD6; // SH
#endif
};

struct SurfaceOutput
{
	half3 Albedo;
	half3 Specular;
	half3 Normal;
	half3 Emission;
	half Smoothness;
	half Occlusion;
	half Alpha;
};

sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _BRDFLut;

float4 _MainTex_ST;
float4 _BumpMap_ST;

half4 _Color;
half _Metallic;
half _Smoothness;

half4 _IndirectDiffuse;
half4 _IndirectSpecular;

// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
inline half3 F_Schlick(half3 f0, half vh)
{
	half fc = pow(1 - vh, 5);
	return fc + (1 - fc) * f0;  
}

// GGX / Trowbridge-Reitz
// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
inline half D_GGX(half roughness, half nh)
{
	half a = roughness * roughness;
	half a2 = a * a;
	half d = (nh * a2 - nh) * nh + 1.00001h;
	return a2 / (d * d + 1e-7);
}

// Appoximation of joint Smith term for GGX
// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
inline half V_SmithJointApprox(half roughness, half nv, half nl)
{
	half a = roughness * roughness;
	half smithV = nl * (nv * (1 - a) + a);
	half smithL = nv * (nl * (1 - a) + a);
	return 0.5 / (smithV + smithL + 1e-5f);
}

inline half4 LightingRealtime(half3 normal, half3 viewDir, half3 lightDir, half roughness,
	half3 albedo, half3 specular, half3 indirectDiffuse, half3 indirectSpecular)
{
	normal = normalize(normal);
	half3 halfDir = normalize(lightDir + viewDir);

	half nv = saturate(dot(normal, viewDir));
	half nl = saturate(dot(normal, lightDir));
	half nh = saturate(dot(normal, halfDir));
	half lh = saturate(dot(lightDir, halfDir));

	half2 AB = tex2D(_BRDFLut, float2(nv, roughness)).xy;
	half3 F0 = specular * AB.x + AB.y;

	half D = D_GGX(roughness, nh);
	half V = V_SmithJointApprox(roughness, nv, nl);
	half3 F = F_Schlick(specular, lh);

	half3 specularTerm = D * V * F;

	half3 color = (albedo + specularTerm) * _LightColor0.rgb * nl + albedo * indirectDiffuse + indirectSpecular * F0;

	return half4(color, 1);
}

inline UnityGI LightingUnityGI(float3 worldPos, half3 normal, half3 viewDir, half3 lightDir, 
	half roughness, fixed atten, half3 albedo, half3 specular, half3 sh)
{
	// Setup lighting environment
	UnityGI gi;
	UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
	gi.indirect.diffuse = 0;
	gi.indirect.specular = 0;
#if !defined(LIGHTMAP_ON)
	gi.light.color = _LightColor0.rgb;
	gi.light.dir = lightDir;
#endif

	// Call GI (lightmaps/SH/reflections) lighting function
	UnityGIInput giInput;
	UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
	giInput.light = gi.light;
	giInput.worldPos = worldPos;
	giInput.worldViewDir = viewDir;
	giInput.atten = atten;

	/*
#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
	giInput.lightmapUV = IN.lmap;
#else
	giInput.lightmapUV = 0.0;
#endif
	*/

#if UNITY_SHOULD_SAMPLE_SH
	giInput.ambient = sh;
#else
	giInput.ambient.rgb = 0.0;
#endif

	giInput.probeHDR[0] = unity_SpecCube0_HDR;
	giInput.probeHDR[1] = unity_SpecCube1_HDR;
#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
	giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
#endif
#if UNITY_SPECCUBE_BOX_PROJECTION
	giInput.boxMax[0] = unity_SpecCube0_BoxMax;
	giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
	giInput.boxMax[1] = unity_SpecCube1_BoxMax;
	giInput.boxMin[1] = unity_SpecCube1_BoxMin;
	giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
#endif

	SurfaceOutput o;
	o.Albedo = albedo;
	o.Specular = specular;
	o.Normal = normal;
	o.Emission = 0.0;
	o.Smoothness = 1 - roughness;
	o.Occlusion = 1.0;
	o.Alpha = 1.0;
	UNITY_GI(gi, o, giInput);

	return gi;
}

VertexOutput vert(VertexInput v)
{
	VertexOutput o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
	UNITY_TRANSFER_INSTANCE_ID(v, o);

	o.pos = UnityObjectToClipPos(v.vertex);
	o.tex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	o.tex.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

	float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
	fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
	fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
	o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
	o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
	o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

	TRANSFER_SHADOW(o);
	UNITY_TRANSFER_FOG(o, o.pos);

#if WP_UNITY_GI
	o.sh = 0;
#if UNITY_SHOULD_SAMPLE_SH
	// Approximated illumination from non-important point lights
#ifdef VERTEXLIGHT_ON
	o.sh += Shade4PointLights(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, worldPos, worldNormal);
#endif
	o.sh = ShadeSHPerVertex(worldNormal, o.sh);
#endif
#endif

	return o;
}

fixed4 frag(VertexOutput IN) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(IN);

	float2 uv_MainTex = IN.tex.xy;
	float2 uv_BumpMap = IN.tex.zw;
	half4 albedo = tex2D(_MainTex, uv_MainTex) * _Color;
	half3 normal = UnpackNormal(tex2D(_BumpMap, uv_BumpMap));
	half3 specular = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, _Metallic);
	half oneMinusReflectivity = (1 - _Metallic) * unity_ColorSpaceDielectricSpec.a;
	half roughness = (1 - _Smoothness * albedo.a);
	albedo *= oneMinusReflectivity;

	float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);

	half3 worldNormal = half3(
		dot(IN.tSpace0.xyz, normal),
		dot(IN.tSpace1.xyz, normal),
		dot(IN.tSpace2.xyz, normal)
	);

	half3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

#ifndef USING_DIRECTIONAL_LIGHT
	half3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
#else
	half3 worldLightDir = _WorldSpaceLightPos0.xyz;
#endif	

	// GI term
#if WP_UNITY_GI
	UNITY_LIGHT_ATTENUATION(atten, IN, worldPos) // compute lighting & shadowing factor
	UnityGI gi = LightingUnityGI(worldPos, worldNormal, worldViewDir, worldLightDir, roughness, atten, albedo, specular, IN.sh);
	half3 indirectDiffuse = gi.indirect.diffuse;
	half3 indirectSpecular = gi.indirect.specular;
#else
	half3 indirectDiffuse = _IndirectDiffuse;
	half3 indirectSpecular = _IndirectSpecular;
#endif

	// realtime lighting: call lighting function
	fixed4 c = LightingRealtime(worldNormal, worldViewDir, worldLightDir, roughness, albedo, specular, indirectDiffuse, indirectSpecular);

	UNITY_APPLY_FOG(IN.fogCoord, c);
	UNITY_OPAQUE_ALPHA(c.a);
	return c;
}

sampler2D _FurLayerTex;
float4 _FurLayerTex_ST;
half _FurLength;
half _FurCutoffStart;
half _FurCutoffEnd;
half _FurEdgeFade;
half3 _FurGravity;
half _FurGravityStrength;

VertexOutput vert_furBias(VertexInput v, half furBias)
{
	half3 direction = lerp(v.normal, _FurGravity * _FurGravityStrength + v.normal * (1 - _FurGravityStrength), furBias);
	v.vertex.xyz += direction * _FurLength * furBias;
	return vert(v);
}

fixed4 frag_furBias(VertexOutput IN, half furBias) : SV_Target
{
	fixed4 c = frag(IN);

	float2 uv_MainTex = IN.tex.xy;
	float2 uv_BumpMap = IN.tex.zw;
	half3 normal = UnpackNormal(tex2D(_BumpMap, uv_BumpMap));
	float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
	half3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
	half3 worldNormal = half3(
		dot(IN.tSpace0.xyz, normal),
		dot(IN.tSpace1.xyz, normal),
		dot(IN.tSpace2.xyz, normal)
		);

	fixed alpha = tex2D(_FurLayerTex, TRANSFORM_TEX(uv_MainTex, _FurLayerTex)).r;
	alpha = step(lerp(_FurCutoffStart, _FurCutoffEnd, furBias), alpha);
	c.a = 1 - furBias * furBias;
	c.a += dot(worldViewDir, worldNormal) - _FurEdgeFade;
	c.a = max(0, c.a);
	c.a *= alpha;

	return c;
}

#endif
