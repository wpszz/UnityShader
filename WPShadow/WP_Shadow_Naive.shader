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
		#pragma surface surf Lambert vertex:vert exclude_path:prepass noforwardadd novertexlights addshadow //addshadow for depth texture 
		#pragma exclude_renderers xbox360 ps3
		#pragma skip_variants UNITY_HDR_ON
		//#pragma multi_compile __ WP_SHADOW_AA

		sampler2D _MainTex;

		uniform sampler2D WP_ShadowMap;
		uniform float4 WP_ShadowMap_TexelSize;
		uniform float4x4 WP_MatrixVPC;
		uniform float4x4 WP_MatrixV;
		uniform float4 WP_ControlParams; // x: intensity y:anti-aliasing z:zNear w:1/(zFar - zNear)

		struct Input {
			float2 uv_MainTex;
			float3 wp_uvz;
		};

		void vert(inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);

			//float cullZ = mul((float3x3)WP_MatrixV, mul((float3x3)unity_ObjectToWorld, v.normal)).z;
			o.wp_uvz = mul(WP_MatrixVPC, mul(unity_ObjectToWorld, v.vertex)).xyz;
			o.wp_uvz.z = -mul(WP_MatrixV, mul(unity_ObjectToWorld, v.vertex)).z;
		}

		inline float LightCameraDepth01(float z) {
			return (z - WP_ControlParams.z) * WP_ControlParams.w;
		}

		inline float SampleDepth(float2 uv)
		{
			return DecodeFloatRGBA(tex2D(WP_ShadowMap, uv));
		}

		inline float ClipShadowDepth(float shadowDepth, float3 uvz)
		{
			float depth = LightCameraDepth01(uvz.z);
			return step(shadowDepth, depth) * step(0.001, shadowDepth)
				* step(0, uvz.x) * step(0, uvz.y) * step(uvz.x, 1) * step(uvz, 1);
		}

		inline float GaussianShadowDepth(float3 uvz, float kernelX, float kernelY, float kernelW) {
			float shadowDepth = SampleDepth(float2(uvz.x + WP_ShadowMap_TexelSize.x * kernelX, uvz.y + WP_ShadowMap_TexelSize.y * kernelY));
			return ClipShadowDepth(shadowDepth, uvz) * kernelW;
		}

		inline float ShadowAtten(float3 uvz) {
			float shadowDepth = 0;
			if (WP_ControlParams.y < 1)
				shadowDepth = ClipShadowDepth(SampleDepth(uvz.xy), uvz);
			else if (WP_ControlParams.y < 2)
			{
				shadowDepth += GaussianShadowDepth(uvz, -1.0, 0.0, 0.3);
				shadowDepth += GaussianShadowDepth(uvz, 0.0, 0.0, 0.4);
				shadowDepth += GaussianShadowDepth(uvz, 1.0, 0.0, 0.3);
			}
			else if (WP_ControlParams.y < 3)
			{
				shadowDepth += GaussianShadowDepth(uvz, -1.0, 0.0, 0.15);
				shadowDepth += GaussianShadowDepth(uvz, 0.0, -1.0, 0.15);
				shadowDepth += GaussianShadowDepth(uvz, 0.0, 0.0, 0.4);
				shadowDepth += GaussianShadowDepth(uvz, 1.0, 0.0, 0.15);
				shadowDepth += GaussianShadowDepth(uvz, 0.0, 1.0, 0.15);
			}
			else
			{
				shadowDepth += GaussianShadowDepth(uvz, -1.0, -1.0, 0.0585);
				shadowDepth += GaussianShadowDepth(uvz, 0.0, -1.0, 0.0965);
				shadowDepth += GaussianShadowDepth(uvz, 1.0, -1.0, 0.0585);
				shadowDepth += GaussianShadowDepth(uvz, -1.0, 0.0, 0.0965);
				shadowDepth += GaussianShadowDepth(uvz, 0.0, 0.0, 0.1529);
				shadowDepth += GaussianShadowDepth(uvz, 1.0, 0.0, 0.0965);
				shadowDepth += GaussianShadowDepth(uvz, -1.0, 1.0, 0.0585);
				shadowDepth += GaussianShadowDepth(uvz, 0.0, 1.0, 0.0965);
				shadowDepth += GaussianShadowDepth(uvz, 1.0, 1.0, 0.0585);
			}
			return 1 - WP_ControlParams.x * shadowDepth;
		}

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);

			o.Albedo = c.rgb;
			o.Alpha = c.a;

			o.Albedo.rgb *= ShadowAtten(IN.wp_uvz);
		}
		ENDCG
	}
	//Fallback "Mobile/VertexLit"
}
