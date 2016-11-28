#version 330

uniform vec2 iResolution;
uniform float iGlobalTime;
float square(vec2 uv, vec2 pos, vec2 size,float smoothness)
{
	vec2 downLeftCorner = smoothstep(pos - smoothness/2,pos+smoothness/2,uv);
	vec2 upperRightCorner = 1 - smoothstep(pos + size - smoothness/2,pos +size + smoothness/2, uv);
	return (downLeftCorner.x * downLeftCorner.y) * (upperRightCorner.x*upperRightCorner.y);
	// return (upperRightCorner.x*upperRightCorner.y);
}
	
float drawLine(vec2 uv,float thickness, float y)
{
	float bottom = step(y-thickness/2, uv.y);
	float top = 1-step(y+thickness/2, uv.y);
	return bottom * top;
}
float drawGrid(vec2 uv, float lineThickness)
{
	// float pos = fract(uv*20);
	return 0;
	
}
float function(float x)
{
	float y = x;

	return y;	
}
float plotFunction(vec2 coord, vec2 screenDelta)
{
	float dist = abs(function(coord.x - coord.y));
	return 1 - smoothstep(0, screenDelta.y,dist);
}
void main()
{
	float scale = 15;

	//create uv to be in the range [0..1]x[0..1]
	vec2 uv = gl_FragCoord.xy / iResolution;
	uv*=scale;
	uv-=scale/2;
	
	// ich geh jetzt her und sage
	
	//dingsdadebumsda
	
	vec4 color = vec4(0,0,0,1);
	
	color.rgb += vec3(smoothstep(0.0,0.02, abs(uv.x)));
	color.rgb -= 1-vec3(smoothstep(0.0,0.02, abs(uv.y)));
	color.rgb -= 0.2*(1-vec3(step(scale/iResolution.x,fract(uv.x))));
	color.rgb -= 0.2*(1-vec3(step(scale/iResolution.y,fract(uv.y))));
	float y = 10*uv.x;
	y = exp(-0.4 * abs(uv.x))*30 * cos(2*uv.x);
	// x = fract(x * 1.5);
	color.rgb -= vec3(0,drawLine(uv, 0.04,y),0); //line ii
	// vec2 x = step(0.5,uv.y);
	// color += vec4(x,0,1);
	
	
	
	//4 component color red, green, blue, alpha
	// vec4 color =  vec4(0.7, 0.5, 0.3, 1); //line i
	// color.rgb = vec3(step(0.5, uv.x)); //line ii
	// color.rgb = vec3(smoothstep(0.45, 0.55, uv.x)); //line iii

	// color.rgb = vec3(square(uv,0.3,0.3,0.3,0.3));
	// color.rgba = vec4(0,0,0,1);
	// vec2 size = vec2(0.9);
	// vec2 dist = vec2(0.01);
	// vec2 coordAspect = uv;
	// coordAspect.x *= iResolution.x / iResolution.y;
	// vec2 pos = mod(coordAspect,0.5);
	
			// float intensity = square(uv,pos,size,0.0065);
			
				// color.rgb += vec3(1,0,0)* intensity ;
			
			// else if(int(pos.x*1000) %4 == 0)
			// {
				// color.rgb +=vec3(0,1,0) * intensity;
			// }else if(int(pos.x*1000) %4 == 1)
			// {
				// color.rgb +=vec3(0,0,1) * intensity;
			// }else if(int(pos.y*1000) %4 == 1)
			// {
				// color.rgb +=vec3(1.0,1.0,0) * intensity;
			// }
			// else {
			
				// color.rgb +=  vec3(1)* intensity ;
			// }
		
	
	// color.rgb = vec3(step(0.5,uv.y));
	// color.rgb = vec3(square(uv,vec2(0.0,1-0.1),vec2(0.1,0.1)),0,0);
	// color.rgb += vec3(square(uv,vec2(0.0,1-0.22),vec2(0.1,0.1)),0,0);
	
	gl_FragColor = color;
}
