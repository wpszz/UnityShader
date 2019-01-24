#ifndef WP_NOISE_INCLUDED
#define WP_NOISE_INCLUDED

inline float random(float n) {
	return frac(sin(n)*1000000.);
}

inline float random(float2 st) {
	return frac(sin(dot(st.xy, float2(12.9898, 78.233)))*43758.5453123);
}

inline float hash(float n) {
	return frac(sin(n) * 1e4);
}

inline float hash(float2 p) {
	return frac(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x))));
}

inline float noise(float x) {
	float i = floor(x);
	float f = frac(x);
	float u = f * f * (3.0 - 2.0 * f);
	return lerp(hash(i), hash(i + 1.0), u);
}

inline float noise(float2 x) {
	float2 i = floor(x);
	float2 f = frac(x);

	// Four corners in 2D of a tile
	float a = hash(i);
	float b = hash(i + float2(1.0, 0.0));
	float c = hash(i + float2(0.0, 1.0));
	float d = hash(i + float2(1.0, 1.0));

	// Simple 2D lerp using smoothstep envelope between the values.
	// return vec3(mix(mix(a, b, smoothstep(0.0, 1.0, f.x)),
	//			mix(c, d, smoothstep(0.0, 1.0, f.x)),
	//			smoothstep(0.0, 1.0, f.y)));

	// Same code, with the clamps in smoothstep and common subexpressions
	// optimized away.
	float2 u = f * f * (3.0 - 2.0 * f);
	return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

inline float noise(float3 x) {
	const float3 step = float3(110, 241, 171);

	float3 i = floor(x);
	float3 f = frac(x);

	// For performance, compute the base input to a 1D hash from the integer part of the argument and the 
	// incremental change to the 1D based on the 3D -> 1D wrapping
	float n = dot(i, step);

	float3 u = f * f * (3.0 - 2.0 * f);
	return lerp(lerp(lerp(hash(n + dot(step, float3(0, 0, 0))), hash(n + dot(step, float3(1, 0, 0))), u.x),
		lerp(hash(n + dot(step, float3(0, 1, 0))), hash(n + dot(step, float3(1, 1, 0))), u.x), u.y),
		lerp(lerp(hash(n + dot(step, float3(0, 0, 1))), hash(n + dot(step, float3(1, 0, 1))), u.x),
			lerp(hash(n + dot(step, float3(0, 1, 1))), hash(n + dot(step, float3(1, 1, 1))), u.x), u.y), u.z);
}

#endif
