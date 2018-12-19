Shader "WP/Shadow/Depth"
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
		Fog { Mode Off }

		Pass
		{
		}
	}
}
