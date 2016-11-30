///idea from http://thebookofshaders.com/edit.php#09/marching_dots.frag
#version 330

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform vec3 iMouse;
const float PI = 3.1415926535897932384626433832795;
const float TWOPI = 2 * PI;
const float EPSILON = 10e-4;

float triangle(vec2 coord, float smoothness)
{
	return smoothstep(1 - smoothness, 1 + smoothness, coord.x + coord.y);
}

float diagonal(vec2 coord, float smoothness)
{
	return smoothstep(coord.x - smoothness, coord.x, coord.y) - smoothstep(coord.x, coord.x + smoothness, coord.y);
}

float circles(vec2 coord)
{
	float a = 0.4;
	float b = 0.6;
	float len = length(coord);
	float len1 = length(coord - vec2(1));
	return (step(len, b) - step(len, a) ) + (step(len1, b) - step(len1, a) );
}

vec2 rotate2D(vec2 coord, float angle)
{
    mat2 rot =  mat2(cos(angle),-sin(angle), sin(angle),cos(angle));
    return rot * coord;
}
float random(float u)
{
	return fract(sin(u) * 1231534.9);
}

float random(vec2 coord) { 
    return random(dot(coord, vec2(21.4597898, 7519.33123)));
}
///map coordinates to angles 0°,90°,180°, 270°
float angle(vec2 coord)
{
	
    float index = trunc(mod(coord.x, 5)) * 3;
        index = trunc(random(trunc(coord.xy))*4 );
	// index = 0;
	return trunc(mod(index, 4)) * 0.5 * PI;
}
float selectTile(vec2 _st, float row, float col)
{
	vec2 newCoords = vec2(0);
	newCoords.x = step(col, _st.x) - step(col+1,_st.x);
	newCoords.y = step(row, _st.y) - step(row+1,_st.y);	
	return newCoords.x*newCoords.y;
}
//truchet style pattern
vec2 truchet(vec2 coord, float scale, float timeScale)
{
	coord *= scale; //zoom
	float angle = angle(coord);
	coord = fract(coord);
	coord -= 0.5;
	// float rotate = step(random(coord),0.7);
	float tile = selectTile(coord,random(coord),random(coord));
	coord = rotate2D(coord*tile, angle + TWOPI * timeScale * iGlobalTime);
	coord += 0.5;
	return coord;
}

void main() {
	//coordinates in range [0,1]
    vec2 coord = gl_FragCoord.xy/iResolution;
	
	coord.x *= iResolution.x / iResolution.y; //aspect
	
	coord = truchet(coord, 7, 0.1);
	// coord = truchet(coord, 3, 0.1);
	// coord = truchet(coord, 2, 0.1);
	
	// coord = truchet(coord, 4, 0.1); //rekursive pattern
	
	float grid = triangle(coord, 0.01);	 
	
	// grid = diagonal(coord, 0.05);
	// grid = circles(coord);

	const vec3 white = vec3(1);
	vec3 color = (1 - grid) * white;
		
    gl_FragColor = vec4(color, 1.0);
}
