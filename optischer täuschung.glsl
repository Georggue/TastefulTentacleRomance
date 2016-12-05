#version 330
#define PI 3.14159265358979323846
uniform vec2 iResolution;
uniform float iGlobalTime;

float smoothBox(vec2 coord, vec2 size, float smoothness){
    size = vec2(0.5) - size * 0.5;
    vec2 uv = smoothstep(size, size + vec2(smoothness), coord);
    uv *= smoothstep(size, size + vec2(smoothness), vec2(1.0) - coord);
    return uv.x*uv.y;
}
float circle(vec2 coord, float radius)
{
    vec2 pos = vec2(0.5) - coord;
    return smoothstep(1 - radius, 1 - radius + radius * 0.2 , 1 - dot(pos, pos) * PI);
}

float polygon(vec2 _st, int sides)
{	
	_st.x -= 0.5;
	_st.y -= 0.5;
	int N = sides;
	float fact = 2*PI/N;
	float r = length(_st); // radius of current pixel
    float a = atan(_st.y, _st.x) + PI; //angel of current pixel [0..2*PI] 
	float f = cos(a - floor(0.5 + a / fact) * fact) * r;
	return smoothstep(0.4, 0.401, f);	
	
}
vec2 brickTile(vec2 _st, float _zoom){
    _st *= _zoom;

    // Here is where the offset is happening
    _st.x += step(1., mod(_st.y,2.0)) * 0.5*iGlobalTime;
	// if(mod(_st.x,3.0) == mod(_st.y,3.0))
	// {
		
	// }
	 _st.y += step(1., mod(_st.x,2.0)) * 0.5*iGlobalTime;
	 // _st.x += step(1., mod(_st.y+1,2.0)) * 0.5*iGlobalTime;
	 // _st.y += step(1., mod(_st.x+1,2.0)) * 0.5*iGlobalTime;

    return fract(_st);
}

void main() {
	//coordinates in range [0,1]
    vec2 coord01 = gl_FragCoord.xy/iResolution;
	vec2 coordAspect = coord01;
	coordAspect.x *= iResolution.x / iResolution.y;
	coordAspect = brickTile(coordAspect,25.0);
	float zeuch = smoothBox(coordAspect, vec2(0.85),0.01);
	// zeuch = circle(coordAspect,0.8);
	// zeuch = 1-polygon(coordAspect,4);
	// vec3 color = vec3(0.5+sin(zeuch*iGlobalTime),0,0.5+sin(zeuch*iGlobalTime*0.7)*cos(zeuch*iGlobalTime*0.6));
	vec3 color = vec3(zeuch);
	
	
	// vignette
	float innerRadius = .45;
	float outerRadius = .65;
	float intensity = .7;
	vec3 vignetteColor = vec3(37,39,68)/255;
	vec2 relativePosition = gl_FragCoord.xy / iResolution -.5;
	relativePosition.y *= iResolution.x / iResolution.y;
	float len = length(relativePosition);
	float vignetteOpacity = smoothstep(innerRadius, outerRadius, len) * intensity;
	color = mix(color, vignetteColor, vignetteOpacity);
	
    gl_FragColor = vec4(color, 1.0);
}