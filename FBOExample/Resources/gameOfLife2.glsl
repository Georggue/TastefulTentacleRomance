uniform sampler2D image;
uniform vec2 iResolution;
uniform vec2 mousePos;
in vec2 uv;
const float PI = 3.1415926535897932384626433832795;

float circle(vec2 coord, float radius)
{
    vec2 pos = vec2(0.5) - coord;
    return smoothstep(1 - radius, 1 - radius + radius * 0.2 , 1 - dot(pos, pos) * PI);
}

int getNumberOfLivingNeighbours()
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
			vec3 checkCol = texture(image, curUV).rgb;
			if(checkCol == vec3(1))
			{
				alive++;
			}
		}
	}
	return alive;
}
void main() {
	vec3 color = texture(image, uv).rgb;
	
	color = vec3(circle(mousePos,0.1));
	
	
		// if(color == vec3(0))
		// {
			// int alive = getNumberOfLivingNeighbours();
			// if(alive == 3)
			// {
				// color = vec3(1);
			// }
		// }
		// else if(color.x > 0)
		// {
			// int alive = getNumberOfLivingNeighbours();
			// if(alive < 2)	//alive lesser 2 -> dead.. so lonely :'-(
			// {
				// color = vec3(0);
			// }else if(alive <= 3) //alive greater 1, lesser 4 -> still alive 
			// {
				// color = vec3(1);
			// }else //alive greater 3 -> Dead
			// {
				// color = vec3(0);
			// }		
		// }
	
		
		
	gl_FragColor = vec4(color, 1.0);
}