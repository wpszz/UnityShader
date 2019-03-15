#ifndef WP_PUR_INCLUDED
#define WP_PUR_INCLUDED

#include "UnityCG.cginc"

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
	fixed3 normal : TEXCOORD1;
	fixed3 viewDir : TEXCOORD2;
};

sampler2D _MainTex;
float4 _MainTex_ST;
half4 _Color;

sampler2D _FurLayerTex;
float4 _FurLayerTex_ST;
half _FurLength;
half _FurCutoffStart;
half _FurCutoffEnd;
half _FurEdgeFade;
half3 _FurGravity;
half _FurGravityStrength;

v2f vert(a2v v, half furBias)
{
	half3 direction = lerp(v.normal, _FurGravity * _FurGravityStrength + v.normal * (1 - _FurGravityStrength), furBias);
	v.vertex.xyz += direction * _FurLength * furBias;

	v2f o;
	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	o.normal = UnityObjectToWorldNormal(v.normal);

	float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.viewDir = UnityWorldSpaceViewDir(worldPos);
	return o;
}

fixed4 frag(v2f i, half furBias) : SV_Target
{
	half3 normal = normalize(i.normal);

	half4 c = tex2D(_MainTex, i.uv) * _Color;
	float diffuse = saturate(dot(normal, _WorldSpaceLightPos0.xyz));
	c.rgb *= diffuse;

	fixed alpha = tex2D(_FurLayerTex, TRANSFORM_TEX(i.uv, _FurLayerTex)).r;
	alpha = step(lerp(_FurCutoffStart, _FurCutoffEnd, furBias), alpha);
	c.a = 1 - furBias * furBias;
	c.a += dot(normalize(i.viewDir), normal) - _FurEdgeFade;
	c.a = max(0, c.a);
	c.a *= alpha;

	return c;
}

#endif
