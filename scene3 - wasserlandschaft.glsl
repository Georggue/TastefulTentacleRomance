// Shows the error (difference between hit-point height and the heightmap's height at that point)
// -- Left: before interval mapping -- Right: after interval mapping
//#define SHOW_ERROR    
#include "libs/camera.glsl"
// Use interval mapping
#define INTERVAL

// Quality settings
// #define LOW
//#define MEDIUM
#define HIGH

#define CLOUDS
#define SHADOWS

#define SHADOW_ITERS 10
#define SHADOW_QUALITY 3.0

#ifdef LOW
	#define LINEAR_ITERS 45
	#define INTERVAL_ITERS 3
	#define LINEAR_ACCURACY 0.7
	#define FOG_BASE 0.08
	#define MAX_DIST 1300.0
#endif

#ifdef MEDIUM
	#define LINEAR_ITERS 80
	#define INTERVAL_ITERS 2
	#define LINEAR_ACCURACY 0.6
	#define FOG_BASE 0.06
	#define MAX_DIST 1500.0
#endif

#ifdef HIGH
	#define LINEAR_ITERS 140
	#define INTERVAL_ITERS 3
	#define LINEAR_ACCURACY 0.5
	#define FOG_BASE 0.04
	#define MAX_DIST 2000.0
	#define AA
#endif

#define PI 3.14159265358979

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D tex0;
//// Noise function by iq

float hash(float n)
{
    return fract(sin(n)*43758.5453123);
}

float noise(in vec2 x)
{
    vec2 p = floor(x);
    vec2 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0;
    float res = mix(mix(hash(n+  0.0), hash(n+  1.0), f.x),
                    mix(hash(n+ 57.0), hash(n+ 58.0), f.x), f.y);
    return res;
}

float noise(in vec3 x)
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;
    float res = mix(mix(mix(hash(n+  0.0), hash(n+  1.0), f.x),
                        mix(hash(n+ 57.0), hash(n+ 58.0), f.x), f.y),
                    mix(mix(hash(n+113.0), hash(n+114.0), f.x),
                        mix(hash(n+170.0), hash(n+171.0), f.x), f.y), f.z);
    return res;
}

//// End iq

vec3 rotate(vec3 p, float theta)
{
	float c = cos(theta), s = sin(theta);
	return vec3(p.x, p.y * c + p.z * s,
				p.z * c - p.y * s);
}

float clouds(vec2 p) {
	float final = noise(p);
	p *= 2.94; final += noise(p) * 0.4;
	p *= 2.87; final += noise(p) * 0.2;
	p *= 2.93; final += noise(p) * 0.1;
	return final;
}

float fbm(vec2 p) {
	float final = noise(p);
	p *= 2.94; final += noise(p) * 0.4;
	p *= 2.87; final += noise(p) * 0.1;
	final += 0.005 + final * 0.005; // Compensate for mssing noise on low quality version
	return pow(final, 1.5) - 1.0;
}

float fbmHigh(vec3 p) {
	float final = noise(p.xz);
	p *= 2.94; final += noise(p.xz) * 0.4;
	p *= 2.87; final += noise(p.xz) * 0.1;
	p *= 2.97; final += noise(p.xz) * final * 0.02;
	final = pow(final, 1.5);
	p *= 1.97; final += noise(p) * final * 0.007;
	p *= 1.99; final += noise(p) * final * 0.002;
	p *= 1.91; final += noise(p) * final * 0.0008;
	return final - 1.0;
}

float terrain(vec2 pos) {
	return fbm(pos * 0.006) * 80.0 - 65.0;
}

float sceneHigh(vec3 pos) {
	return pos.y - fbmHigh(pos * 0.006) * 80.0 + 65.0;
}

vec3 normal(vec3 p) {
	const vec2 eps = vec2(0.1, 0.0);
	float h = terrain(p.xz);
	return normalize(vec3(
		(terrain(p.xz+eps.xy)-h),
		eps.x,
		(terrain(p.xz+eps.yx)-h)
	));
}

vec3 normalHigh(vec3 x) {
	const vec2 eps = vec2(0.1, 0.0);
	float h = sceneHigh(x);
	return normalize(vec3(
		(sceneHigh(x+eps.xyy)-h),
		(sceneHigh(x+eps.yxy)-h),
		(sceneHigh(x+eps.yyx)-h)
	));
}

float shadow(vec3 rpos, vec3 rdir) {
	float t = 1.0+SHADOW_QUALITY;
	float sh = 1.0;
	for (int i = 0; i < SHADOW_ITERS; i++) {
		vec3 pos = rpos + rdir * t;
		float h = pos.y - terrain(pos.xz);
		if (h < 0.0) return 0.0;
		sh = min(sh, h/t*8.0);
		t += max(h, SHADOW_QUALITY);
	}
	return sh;
}

const float waterHeight = 105.0;
const vec3 lightDir = vec3(0.819232, 0.573462, 0.);

vec3 calculateFogColor(vec3 rpos, vec3 rdir) {
	vec3 col = mix(vec3(0.3, 0.5, 0.7), vec3(0.0, 0.05, 0.1), clamp(rdir.y*2.5, 0.0, 1.0));
	col += pow(dot(lightDir, rdir) * 0.5 + 0.5, 2.0) * vec3(0.3, 0.2, 0.1);	
	return col;
}

vec3 shade(vec3 rpos, vec3 rdir, float t, vec3 pos) {
	float watert = ((rpos.y - waterHeight) / rdir.y);
	
	// Calculate fog
	float b = 0.01;
	float fogt = min(watert, t);
	float fog = 1.0 - FOG_BASE * exp(-rpos.y*b) * (1.0-exp(-fogt*rdir.y*b)) / rdir.y;
	vec3 fogColor = calculateFogColor(rpos, rdir);

	vec4 ns = texture2D(tex0, pos.xz * 0.1);
	
	if (fog < 0.01) return fogColor;
	
	vec3 nl = normal(pos);
	vec3 n = normalHigh(pos);
	float h = pos.y;
	
	float slope = n.y;
	vec3 albedo = vec3(0.36, 0.25, 0.15);
	
	// Apply texture above water
	if (watert > t) {
		float snowThresh = 1.0 - smoothstep(-50.0, -40.0, h) * 0.4 + 0.1;
		float grassThresh = smoothstep(-70.0, -50.0, h) * 0.3 + 0.75;
		
		if (nl.y < 0.65)
			albedo = mix(albedo, vec3(0.65, 0.6, 0.5), smoothstep(0.65,0.55,nl.y));
		if (slope > grassThresh - 0.1)
			albedo = mix(albedo, vec3(0.4, 0.6, 0.2), smoothstep(grassThresh-0.1,grassThresh+0.1,slope));
		if (slope > snowThresh - 0.1)
			albedo = mix(albedo, vec3(1.0, 1.0, 1.0), smoothstep(snowThresh-0.1,snowThresh+0.1,slope));
	}
	
	// Fade in 'beach' and add a bit of noise
	albedo = mix(albedo, vec3(0.6, 0.5, 0.2), smoothstep(-waterHeight+4.0,-waterHeight+0.5,h));
	albedo *= ns.rgb * 0.1 + 0.95;
	
	// Lighting
	float diffuse = clamp(dot(n, lightDir), 0.0, 1.0);
	#ifdef SHADOWS
	if (diffuse > 0.005) diffuse *= shadow(pos, vec3(lightDir.xy, -lightDir.z));
	#endif
	vec3 col = vec3(0.0);
	col += albedo * vec3(1.0, 0.9, 0.8) * diffuse;
	col += albedo * fogColor * max(n.y * 0.5 + 0.5, 0.0) * 0.5;
	
	// Shade water
	if (t >= watert) {
		float dist = t - watert;
		vec3 wpos = rpos+rdir*watert;
		col *= exp(-vec3(0.3, 0.15, 0.08)*dist);
		
		float f = 1.0 - pow(1.0 - clamp(-rdir.y, 0.0, 1.0), 5.0);
		vec3 refldir = rdir * vec2(-1.0, 1.0).yxy;
		refldir = normalize(refldir + ns.xyz * 0.1);
		vec3 refl = calculateFogColor(wpos, refldir);
		col = mix(refl, col, f);
	}
	
	return mix(fogColor, col, fog);
}

vec3 trace(vec3 rpos, vec3 rdir) {
	float t = (rpos.y - 10.0) / rdir.y;
	float tfar = (rpos.y - 150.0) / rdir.y;
	float cloudst = (rpos.y + 130.0) / rdir.y;
	float dt = (tfar - t) / 80.0;
	
	if (t > 0.0 && tfar > t) {
		float prevt = 0.0, prevh, dist;
		vec3 pos = vec3(0.0);
		float h = 0.0;
		
		/// Distance map search
		for (int i = 0; i < LINEAR_ITERS; i++) {
			pos = rpos + rdir * t;
			prevh = h;
			h = terrain(pos.xz);
			dist = pos.y - h;
			if (dist < 0.0) break;
			prevt = t;
			
			if (dist > 30.0)
				t += max(dist * 1.2, t * 0.03) * LINEAR_ACCURACY;
			else
				t += max(dist, 5.0) * LINEAR_ACCURACY;
				
			if (t > tfar || t > MAX_DIST) return calculateFogColor(rpos, rdir);
		}
				
		#ifdef SHOW_ERROR
		if (fragCoord.x < iResolution.x*0.5) return vec3(abs(dist*0.1));
		#endif
			
		/// Interval mapping
		#ifdef INTERVAL
		float before = prevt;
		vec3 beforePos = rpos + rdir * before;
		float beforeH = terrain(beforePos.xz);
		
		float after = t;
		vec3 afterPos = rpos + rdir * after;
		float afterH = terrain(afterPos.xz);
		
		float best = before;
		for (int i = 0; i < INTERVAL_ITERS; i++)
		{
			float interval = before - after;
			float deltaL = beforeH - afterH;
			float deltaR = rdir.y * interval;
			
			float curt = (beforeH * interval - deltaL * before) / (deltaR - deltaL);
			if (curt < before - 1.0 || curt > after + 1.0) break;
			
			pos = rpos + rdir * curt;
			float height = terrain(pos.xz);
			dist = height - pos.y;
			
			if (height < pos.y)
			{
				beforeH = height;
				before = curt;
				t = curt;
			}
			else
			{
				afterH = height;
				after = curt;
				t = curt;
			}
		}
		#endif
		
		#ifdef SHOW_ERROR
		return vec3(abs(dist*0.1));
		#endif
		
		return shade(rpos, rdir, t, rpos + rdir * t);
	}
	#ifdef CLOUDS
	else if (cloudst > 0.0) {
		vec3 fc = calculateFogColor(rpos, rdir);
		float f = 1.0/exp(cloudst*0.0005);
		
		vec3 pos = rpos + rdir * cloudst;
		float c = clouds(pos.xz*0.005);
		float c2 = clouds((pos.xz+vec2(50.0, 0.0))*0.005);
		float dir = max((c-c2)+0.5, 0.0);
		
		c = max(c - 0.5, 0.0) * 1.8;
		c = c*c*(3.0-2.0*c);
		vec3 col = mix(vec3(0.4, 0.5, 0.6), vec3(1.0, 0.9, 0.8), dir);
		return mix(fc, col, clamp(f*c, 0.0, 1.0));
	}
	#endif
	
	return calculateFogColor(rpos, rdir);
}

// Ray-generation
vec3 camera(vec2 px) {
	// vec2 rd = (px / iResolution.yy - vec2(iResolution.x/iResolution.y*0.5-0.5, 0.0)) * 2.0 - 1.0;
	vec3 rpos = vec3(iGlobalTime*2.0, 0.0, iGlobalTime*20.0);	
	// vec3 rdir = rotate(vec3(rd.x*0.5, rd.y*0.5, 1.0), -0.2);
	vec3 camP = calcCameraPos();
	camP.z += -3.0;
	camP.y += 0.3;
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	return trace(rpos, normalize(camDir));
}

void mainImage() {
	#ifdef AA
	vec3 col = (camera( gl_FragCoord.xy) + camera( gl_FragCoord.xy + vec2(0.0, 0.5))) * 0.5;
	#else
	vec3 col = camera( gl_FragCoord.xy);
	#endif
	gl_FragColor = vec4(pow(col, vec3(0.4545)), 1.0);
}
void main(){
	mainImage();
}
