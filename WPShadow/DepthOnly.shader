Shader "WP/DepthOnly"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Cull Back
		ColorMask 0
		ZWrite On

		Pass
		{
		}
	}
}
