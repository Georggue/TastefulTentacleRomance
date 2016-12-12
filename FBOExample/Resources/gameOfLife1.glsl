uniform sampler2D image;
uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float iGlobalTime;
in vec2 uv;

const float PI = 3.1415926535897932384626433832795;
vec2 opRepeat(vec2 point, vec2 c)
{
    return mod(point, c) * c;
}
float rand(float seed)
{
	return fract(sin(seed) * 1231534.9);
}

//value noise: random values at integer positions with interpolation inbetween
float noise(float u)
{
	float i = floor(u); // integer position

	//random value at nearest integer positions
	float v0 = rand(i);
	float v1 = rand(i + 1);

	float f = fract(u);
	float weight = f; // linear interpolation
	// weight = smoothstep(0, 1, f); // cubic interpolation

	return mix(v0, v1, weight);
}

//gradient noise: random gradient at integer positions with interpolation inbetween
float gnoise(float u)
{
	float i = floor(u); // integer position
	
	//random gradient at nearest integer positions
	float g0 = 2 * rand(i) - 1; // gradient_0
	float g1 = 2 * rand(i + 1) - 1; // gradient_1

	float f = fract(u);
	float v0 = dot(g0, f);
	float v1 = dot(g1, f - 1);
	
	float weight = f; // linear interpolation
	// weight = smoothstep(0, 1, f); // cubic interpolation

	return mix(v0, v1, weight) + 0.5;
}

float circle(vec2 coord, float radius)
{
    // vec2 pos = iMouse - coord;
	// vec2 pos = coord;
	// pos = opRepeat(pos, vec2(0.25));
	// pos = fract(pos);
	// float uneven = step(1, mod(pos.y, 4));
	// pos.y += uneven*0.5;
	if(distance(coord,uv) < radius)
	{
		return 1;
	}else
	{
		return 0;
	}	
    // return smoothstep(1 - radius, 1 - radius + radius * 0.2 , 1 - dot(pos, pos) * PI);
}
float grid(vec2 pos, float zoom)
{	
	pos*=50;
	pos += gnoise(pos.x);
	vec2 fractCoord;
	fractCoord.x = fract(gnoise(sin(iGlobalTime))-pos.x);
	fractCoord.y = fract(gnoise(cos(iGlobalTime))-pos.y);
	return circle(fractCoord,0.05);
}
int getNumberOfLivingNeighbours(int centerIsAlive)
{
	int alive = 0;
	vec2 curUV;
	for(int x=-1;x<=1;x++)
	{
		for(int y=-1;y<=1;y++)
		{
			curUV = uv;
			curUV.x += x/iResolution.x;
			curUV.y += y/iResolution.y;
			float living = texture2D(image, curUV).a;
			if(living > .0)
			{
				alive++;
			}
		}
	}	
	return alive-centerIsAlive;
}
float calcStep()
{
	bool isAlive = texture2D(image, uv).a > 0.0;
	int alive = isAlive ? 1 : 0;
	int neighbors = getNumberOfLivingNeighbours(alive);
	
	if (isAlive)
	{
		return ( (2 == neighbors) || (3 == neighbors) ) ? 1.0 : 0.0;
	}
	else 
	{
		return (3 == neighbors) ? 1.0 : 0.0;
	}
}
void main() {
	
		float stuff = calcStep() + grid(uv,.01);
		vec3 color = vec3(0.3+sin(iGlobalTime),0.4+cos(iGlobalTime),0.6+sin(iGlobalTime)*cos(iGlobalTime)) * stuff;		
		
		color += 0.99 * texture2D(image, uv).rgb;
		color -= 1.0 / 256.0; //dim over time
		
	gl_FragColor = vec4(color, stuff);
}