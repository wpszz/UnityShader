Shader "WP/Shadow/Naive"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 150

		CGPROGRAM
		#pragma surface surf Lambert vertex:vert exclude_path:prepass noforwardadd novertexlights //noshadow
		#pragma exclude_renderers xbox360 ps3
		#pragma skip_variants UNITY_HDR_ON
		//#pragma multi_compile __ WP_SHADOW_AA

		sampler2D _MainTex;

		uniform sampler2D WP_ShadowMap;
		uniform float4 WP_ShadowMap_TexelSize;
		uniform float4x4 WP_MatrixVPC;
		uniform float4x4 WP_MatrixV;
		uniform float WP_AA;
		uniform float WP_Identity;

		struct Input {
			float2 uv_MainTex;
			float3 wp_uvz;
		};

		void vert(inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);

			float cullZ = mul((float3x3)WP_MatrixV, mul((float3x3)unity_ObjectToWorld, v.normal)).z;
			o.wp_uvz = mul(WP_MatrixVPC, mul(unity_ObjectToWorld, v.vertex)).xyz;
			// w component always is 1 in orthograhpic clip space, so dont need perspective division.
			// convert to depth[0, 1] simply from ndc z component
			o.wp_uvz.z = o.wp_uvz.z * 0.5 + 0.5;
			o.wp_uvz *= step(0, cullZ);
		}

		inline float ClipShadowDepth(float shadowDepth, float3 uvz)
		{
			return step(shadowDepth, uvz.z) * step(shadowDepth - 0.9, 0)
				* step(0, uvz.x) * step(0, uvz.y) * step(uvz.x, 1) * step(uvz, 1);
		}

		inline float GaussianShadowDepth(float3 uvz, float kernelX, float kernelY, float kernelW) {
			float shadowDepth = tex2D(WP_ShadowMap, float2(uvz.x + WP_ShadowMap_TexelSize.x * kernelX, uvz.y + WP_ShadowMap_TexelSize.y * kernelY)).r;
			return ClipShadowDepth(shadowDepth, uvz) * kernelW;
		}

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);

			o.Albedo = c.rgb;
			o.Alpha = c.a;

			float shadowDepth = 0;
			if (WP_AA > 0)
			{
				/* anti-aliasing */
				shadowDepth += GaussianShadowDepth(IN.wp_uvz, -1.0, -1.0, 0.0585);
				shadowDepth += GaussianShadowDepth(IN.wp_uvz, 0.0, -1.0, 0.0965);
				shadowDepth += GaussianShadowDepth(IN.wp_uvz, 1.0, -1.0, 0.0585);
				shadowDepth += GaussianShadowDepth(IN.wp_uvz, -1.0, 0.0, 0.0965);
				shadowDepth += GaussianShadowDepth(IN.wp_uvz, 0.0, 0.0, 0.1529);
				shadowDepth += GaussianShadowDepth(IN.wp_uvz, 1.0, 0.0, 0.0965);
				shadowDepth += GaussianShadowDepth(IN.wp_uvz, -1.0, 1.0, 0.0585);
				shadowDepth += GaussianShadowDepth(IN.wp_uvz, 0.0, 1.0, 0.0965);
				shadowDepth += GaussianShadowDepth(IN.wp_uvz, 1.0, 1.0, 0.0585);
			}
			else
				shadowDepth = ClipShadowDepth(tex2D(WP_ShadowMap, IN.wp_uvz.xy).r, IN.wp_uvz);
			float atten = WP_Identity * shadowDepth;
			o.Albedo.rgb *= (1 - atten);
		}
		ENDCG
	}
	//Fallback "Mobile/VertexLit"
}
