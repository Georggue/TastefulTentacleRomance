#version 330
#include "../libs/camera.glsl"
#include "../../libs/Noise.glsl"
uniform vec3 iMouse;
uniform float iGlobalTime;
uniform vec2 iResolution;
uniform sampler2D tex;

#define RAYMARCHSTEPS 550

float time = iGlobalTime;

//
// math functions
//

const mat2 mr = mat2 (0.84147,  0.54030,
					  0.54030, -0.84147 );
					  
// float rand( in float n ) 
// {
	// return fract(sin(n)*43758.5453);

// }
// float noise(in vec2 x) 
// {
	// vec2 p = floor(x);
	// vec2 f = fract(x);
		
	// f = f*f*(3.0-2.0*f);	
	// float n = p.x + p.y*57.0;
	
	// float res = mix(mix( rand(n+  0.0), rand(n+  1.0),f.x),
					// mix( rand(n+ 57.0), rand(n+ 58.0),f.x),f.y);
	// return res;
// }
float absNoise(vec2 coord)
{
	return abs((gnoise(coord) - 0.5) * 2);
}

float ridgeNoise(vec2 coord)
{
	float a = absNoise(coord);
	a = 1 - a;
	a *= a;
	return a;
}
//fractal Brownian motion
float fBm(vec2 coord) {
	
	int octaves = 6;
    float value = 0;
    float amplitude = 0.5;
	float lacunarity = 2;
	float gain = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), 
                    -sin(0.5), cos(0.5));
    for (int i = 0; i < octaves; ++i) {
		coord += time*(octaves-i)/100;
        value += amplitude * gnoise(coord);
        coord = rot * coord * lacunarity + shift;
        amplitude *= gain;
    }
    return value;
}

float fbm( in vec2 p ) 
{
	float f;
	f  =      0.5000*absNoise( p + time*0.5); p = mr*p*2.02;
	f +=      0.2500*absNoise( p + time*0.3); p = mr*p*2.33;
	f +=      0.1250*absNoise( p + time*0.2 ); p = mr*p*2.01;
	f +=      0.0625*absNoise( p + time*0.1); p = mr*p*5.21;
	// f +=      0.005*noise( p ); 
	return f/(0.9375);
}

float detailFbm( in vec2 p ) {
	float f;
		f  =      0.5000*absNoise( p + time*0.5); p = mr*p*2.02;
	f +=      0.2500*absNoise( p + time*0.3); p = mr*p*2.33;
	f +=      0.1250*absNoise( p + time*0.2 ); p = mr*p*2.01;
	f +=      0.0625*absNoise( p + time*0.1); p = mr*p*5.21;
	f +=      0.005*absNoise( p ); 
	return f/(0.9375);
}

//
// Scene
//

float mapHeight( vec2 p ) 
{
	return fbm(  p*0.35 )*4.;
}

float detailMapHeight( vec2 p ) 
{
	return detailFbm(  p*0.35 )*4.;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 q = fragCoord.xy/iResolution.xy;
	vec2 p = vec2(-1.0)+2.0*q;
	p.x *= iResolution.x/iResolution.y;
	
	vec2 pos = vec2( -0.5, iGlobalTime + 5.5);
	
	vec3 ro = vec3( pos.x, mapHeight( pos )+2.85, pos.y );
	vec3 rd = ( vec3(p, 1. ) );
	
	vec3 camP = calcCameraPos();
	camP.x += 11.0;
	camP.z += -12.0;
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	ro = camP;
	rd = camDir;
	float dist;
	vec3 col = vec3(0.);
	vec3 intersection = vec3(9999.);
	
	// terrain - raymarch
	float t, h = 0.;
	const float dt=0.05;
	
	t = mod( ro.z, dt );
	
	for( int i=0; i<RAYMARCHSTEPS; i++) {
		if( h < intersection.y ) {
			t += dt;
			intersection = ro + rd*t;
			
			h = mapHeight( intersection.xz );
		}
	}
	if( h > intersection.y ) {	
		// calculate projected height of intersection and previous point
		float h1 = (h-ro.y)/(rd.z*t);
		vec3 prev =  ro + rd*(t-dt);
		float h2 = (mapHeight( prev.xz )-ro.y)/(rd.z*(t-dt));
				
		float dx1 = detailMapHeight( intersection.xz+vec2(0.001,0.0) ) - detailMapHeight( intersection.xz+vec2(-0.001, 0.0) );
		dx1 *= (1./0.002);
		float dx2 = detailMapHeight( prev.xz+vec2(0.001,0.0) ) - detailMapHeight( prev.xz+vec2(-0.001, 0.0) );
		dx2 *= (1./0.002);
		
		float dx = mix( dx1, dx2, clamp( (h1-p.y)/(h1-h2), 0., 1.));
		
		col = mix( vec3(.0,0.8,0.2), vec3(0.5,0.,0.), 0.5+0.25*dx );

	}
	
	fragColor = vec4(col,1.0);
}

void main()
{
	mainImage(gl_FragColor, gl_FragCoord.xy);
}