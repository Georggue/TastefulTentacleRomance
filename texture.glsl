#version 330
#include "./libs/Noise.glsl"
uniform vec2 iResolution;
uniform float iGlobalTime;
#define PI 3.14159265358979323846
uniform sampler2D tex0;
uniform sampler2D tex1;
uniform vec3 iMouse;


float smoothBox(vec2 coord, vec2 size, float smoothness){
    size = vec2(0.5) - size * 0.5;
    vec2 uv = smoothstep(size, size + vec2(smoothness), coord);
    uv *= smoothstep(size, size + vec2(smoothness), vec2(1.0) - coord);
    return uv.x*uv.y;
}
vec2 rotate2D (vec2 _st, float _angle) {
   
    _st =  mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle))*_st;
    
    return _st;
}
float selectTile(vec2 _st, float row, float col)
{
	vec2 newCoords = vec2(0);
	newCoords.x = step(col, _st.x) - step(col+1,_st.x);
	newCoords.y = step(row, _st.y) - step(row+1,_st.y);	
	return newCoords.x*newCoords.y;
}

float repeatStep(float x, float width)
{
	return step(0.5 * width, mod(x, width));
}

float stepFunction(int from, int to,float axis)
{
	return step(from,axis) - step(to,axis);
}

void main() {
	//coordinates in range [0,1]
    vec2 coord01 = gl_FragCoord.xy/iResolution;
	vec2 coordAspect = coord01;
	coordAspect.x *= iResolution.x / iResolution.y;

	vec3 color = vec3(0);
	/*coord01*=1.5;
	coord01.x +=0.75;
	coord01.y -=0.20;	
	//Y-Shwobble for Title
	float Frequency = 15.0;
	float Phase = iGlobalTime * 3.0;
	float Amplitude = 0.035;
	
	coord01.y += fBm(coord01.x * Frequency  + Phase) * Amplitude;	
	
	//X-Shwobble for Title
	Frequency = 25.0;
	Phase = iGlobalTime * 4.0;
	Amplitude = 0.01;
	coord01.x += fBm(coord01.y * Frequency  + Phase) * Amplitude;	
	
	color.rgb += texture2D(tex0,coord01).rgb * selectTile(coord01,0.1,1);
		
	float gray = (color.r + color.r + color.b + color.g + color.g + color.g)/6;
	color.r += 0.1*(1-gray);
	color.b += 0.3*gray;
	
	// vignette
	vec2 relativePosition = gl_FragCoord.xy / iResolution -.5;
	vec2 center = vec2(.5, .5); // center of screen
	float distCenterUV = distance(center,relativePosition)*1.3;
	float innerVig = 0.38;
	float outerVig = .6;	
	float intensity = .7;
	// vec3 vignetteColor = vec3(37,39,68)/255;
	vec3 vignetteColor = vec3(0);
	float len = length(relativePosition);
	float vignetteOpacity = smoothstep(innerVig, outerVig, len) * intensity;
	color = mix(color, vignetteColor, vignetteOpacity);
	*/
	color.rgb += texture2D(tex0,coord01).rgb;
    gl_FragColor = vec4(color, 1.0);
}