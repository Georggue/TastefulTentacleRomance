#version 330

const float PI = 3.14159265359;
const float TWOPI = 2 * PI;
const float EPSILON = 10e-4;

uniform vec2 iResolution;
uniform float iGlobalTime;

void main(){
    vec2 uv = gl_FragCoord.xy/iResolution.xy;
    vec3 color = vec3(0.0);

	// range [-1..1]²
    uv = vec2(1) - 2 * uv;
	//aspect correction
	uv.x *= iResolution.x / iResolution.y;
	
	//cartesian to polar coordinates
    float r = length(uv); // radius of current pixel
    float a = atan(uv.y, uv.x) + PI; //angel of current pixel [0..2*PI] 
	
	float f = a / TWOPI;
	// f = cos(a);
	// f = cos(4 * a);
	// f = abs(cos(4 * a));
    // f = abs(cos(2.5 * a)) * 0.6 + 0.3;
    // f = abs(cos(12 * a) * sin(3 * a)) * 0.8 + 0.1;
    // f = smoothstep(-0.5, 1, cos(10 * a)) * 0.15 + 0.6;

	//sides
	int N = 6;
	float fact = TWOPI/N;
	// f = floor(0.5 + a / fact) * fact;
	// f = floor(0.5 + a / fact) * fact - a;
	// f = cos(a - floor(0.5 + a / fact) * fact);
	f = cos(a - floor(0.5 + a / fact) * fact) * r;

    // color = vec3(f);
	color = vec3(smoothstep(0.4, 0.401, f));	
    // color = vec3(smoothstep(f, f + 0.02, r));

    gl_FragColor = vec4(color, 1.0);
}
