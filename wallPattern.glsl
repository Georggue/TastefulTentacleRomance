#version 330

uniform vec2 iResolution;
uniform float iGlobalTime;
#define PI 3.14159265358979323846
uniform sampler2D tex0;
uniform sampler2D tex1;

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
vec3 heart(vec2 p)
{
	p -= 0.5;
	p*=2.25;
	 float tt = mod(iGlobalTime,1.5)/1.5;
    float ss = pow(tt,.2)*0.5 + 0.5;
    ss = 1.0 + ss*0.5*sin(tt*6.2831*3.0 + p.y*0.5)*exp(-tt*4.0);
    p *= vec2(0.5,1.5) + ss*vec2(0.5,-0.5);
	vec3 bcol = vec3(0);

	float a = atan(p.x,p.y)/3.141593;
    float r = length(p);
    float h = abs(a);
    float d = (13.0*h - 22.0*h*h + 10.0*h*h*h)/(5.0-4.0*h);
	float s = 0.75 + 0.75*p.x;
	s *= 1.0-0.25*r;
	s = 0.5 + 0.6*s;
	s *= 0.5+0.5*pow( 1.0-clamp(r/d, 0.0, 1.0 ), 0.1 );
	vec3 hcol = vec3(1.0,0.65*r,0.35)*s;
	
    return mix( bcol, hcol, smoothstep( -0.01, 0.01, d-r) );
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
float stepFunction(int from, int to,float axis)
{
	return step(from,axis) - step(to,axis);
}
// float alternatingRowSelect(int from,vec2 _st)
// {
	// float tile = (stepFunction(from,from+1,_st.y))*mod(_st.x,2);
	// float tile_1 = (stepFunction(from,from+1,_st.y))*mod(_st.x+1,2);
	// return tile+tile_1;
// }
vec3 grid(vec2 _st, float _zoom){
    _st *= 10;
	
    // Here is where the offset is happening
   
	
	// _st.y += step(1.,_st.y)* step(2,mod(iGlobalTime,4.0));
	// _st.x += step(1.,_st.x)* step(2,mod(iGlobalTime,4.0));
	
	_st.y += direction(_st.x)* move(iGlobalTime);
	_st.x += direction(_st.y)* move(iGlobalTime+1);

	float tile = (stepFunction(4,5,_st.y))*mod(_st.x,2);
	float tile2 =(stepFunction(5,6,_st.x))*mod(_st.y,2);
	 
	float tile3 = (stepFunction(6,7,_st.x))*mod(_st.y,2);
	float tile4 = (stepFunction(5,6,_st.y))*mod(_st.x,2);
	
	float tile_1 = (stepFunction(4,5,_st.y))*mod(_st.x+1,2);
	float tile2_1 =(stepFunction(5,6,_st.x))*mod(_st.y+1,2);
	 
	float tile3_1 = (stepFunction(6,7,_st.x))*mod(_st.y+1,2);
	float tile4_1 = (stepFunction(5,6,_st.y))*mod(_st.x+1,2);
	
	// float tile2_1 = (step(5, _st.x) - step(6,_st.x))*mod(_st.y+1,2);
	// float tile3 = step(5, _st.y) - step(6,_st.y)*mod(_st.x,2);;
	// float tile3_1 = step(5, _st.y) - step(6,_st.y);
	// float tile4 = step(6, _st.x) - step(7,_st.x)*mod(_st.y,2);;
	// float tile4_1 = step(6, _st.x) - step(7,_st.x);
	
	
	vec2 fractCoord = fract(_st);
	fractCoord-=.5;
	// if(tile == 1)
	// {
		// fractCoord = rotate2D(fractCoord ,tile*iGlobalTime);
	// }else if(tile2==1)
	// {
		// fractCoord = rotate2D(fractCoord,tile2*iGlobalTime);
	// }
	
	// fractCoord = rotate2D(fractCoord,(tile+tile2+tile3+tile4)*iGlobalTime);
		// col.rgb += (texture2D(tex1, uv.xy*2).x)*0.25;

	fractCoord += 0.5;
	// currentCoords = fractCoord;
	 // _st.y += step(1., mod(_st.x,2.0)) * 0.5*iGlobalTime;
	// vec3 col = vec3(polygon(fractCoord,2));
	// fractCoord *=sin(iGlobalTime);
	vec3 col = heart(fractCoord);
	
	float tileSum1 = tile + tile2 + tile3_1 + tile4_1;
	float tileSum2 = tile3 + tile4 + tile_1 + tile2_1;
	if(tileSum1  >= 1 && (tileSum2 <= 3))
	{
		// col = texture2D(tex0,_st.xy).rgb ;
		
	}	
	if(tileSum2 >=1 && (tileSum1 <= 3))
	{
		// col = texture2D(tex1,_st.xy).rgb;
	}	
    return col;
}
void main() {
	//coordinates in range [0,1]
    vec2 coord01 = gl_FragCoord.xy/iResolution;
	vec2 coordAspect = coord01;
	coordAspect.x *= iResolution.x / iResolution.y;
	
	// coordAspect.x -=0.6;
	// coordAspect.y -=0.6;
	// coordAspect*=3;
	vec3 grid = grid(coordAspect,10.0);
	// float poly = 1-polygon(coordAspect,6);	
	
    // coordAspect.x += step(1., mod(coordAspect.y,2.0)) * 0.5;
	// vec3 triangleGridColor = polygon(coordAspect,3,0.2);
	// float boxColor = smoothBox(coordAspect, vec2(0.85),0.01);
	// vec3 color = vec3(boxColor);
	
	float tile = selectTile(coordAspect,5.0,5.0);
	
	vec3 color = grid;
	coord01*=2;
	coord01.x +=0.5;
	coord01.y -=0.5;		
	// if(coord01.x >= 1 && coord01.y<=1 && coord01.x <= 2 && coord01.y >= 0)
	// {
		color.rgb += texture2D(tex0,coord01).rgb * selectTile(coord01,0.1,1);
		
	// }
	
	float gray = (color.r + color.r + color.b + color.g + color.g + color.g)/6;
	color.r += 0.1*(1-gray);
	color.b += 0.3*gray;
	
	// vignette
	float innerRadius = .45;
	float outerRadius = .65;
	float intensity = .7;
	vec3 vignetteColor = vec3(0,0,0)/255;
	vec2 relativePosition = gl_FragCoord.xy / iResolution -.5;
	relativePosition.y *= iResolution.x / iResolution.y;
	float len = length(relativePosition);
	float vignetteOpacity = smoothstep(innerRadius, outerRadius, len) * intensity;
	color = mix(color, vignetteColor, vignetteOpacity);
	
    gl_FragColor = vec4(color, 1.0);
}