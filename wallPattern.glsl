#version 330

uniform vec2 iResolution;
uniform float iGlobalTime;
#define PI 3.14159265358979323846

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
float repeatStep(float x, float width)
{
	return step(0.5 * width, mod(x, width));
}

float move(float time)
{
	float timeStepped = time * repeatStep(time, 2);
	return timeStepped;
}
float direction(float x)
{
	float uneven = step(1, mod(x, 2));
    return sign(uneven - 0.5);
}
float grid(vec2 _st, float _zoom){
    _st *= 10;
	
    // Here is where the offset is happening
   
	_st.y += direction(_st.x)* move(iGlobalTime);
	_st.x += direction(_st.y)* move(iGlobalTime+1);
	// _st.y += step(1.,_st.y)* step(2,mod(iGlobalTime,4.0));
	
	float tile = selectTile(_st,4,4);
		
	vec2 fractCoord = fract(_st);
	// fractCoord -= 0.5;
	// fractCoord = rotate2D(fractCoord ,tile*iGlobalTime);
	// fractCoord += 0.5;
	// currentCoords = fractCoord;
	 // _st.y += step(1., mod(_st.x,2.0)) * 0.5*iGlobalTime;

    return 1-circle(fractCoord,0.5);
}
void main() {
	//coordinates in range [0,1]
    vec2 coord01 = gl_FragCoord.xy/iResolution;
	vec2 coordAspect = coord01;
	coordAspect.x *= iResolution.x / iResolution.y;
		
	float grid = grid(coordAspect,10.0);
	// float poly = 1-polygon(coordAspect,6);	
	
    // coordAspect.x += step(1., mod(coordAspect.y,2.0)) * 0.5;
	// vec3 triangleGridColor = polygon(coordAspect,3,0.2);
	// float boxColor = smoothBox(coordAspect, vec2(0.85),0.01);
	// vec3 color = vec3(boxColor);
	
	float tile = selectTile(coordAspect,5.0,5.0);
	vec3 color = vec3(1)*grid;
    gl_FragColor = vec4(color, 1.0);
}