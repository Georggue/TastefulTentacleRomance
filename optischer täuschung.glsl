#version 330

uniform vec2 iResolution;
uniform float iGlobalTime;

float smoothBox(vec2 coord, vec2 size, float smoothness){
    size = vec2(0.5) - size * 0.5;
    vec2 uv = smoothstep(size, size + vec2(smoothness), coord);
    uv *= smoothstep(size, size + vec2(smoothness), vec2(1.0) - coord);
    return uv.x*uv.y;
}
vec2 brickTile(vec2 _st, float _zoom){
    _st *= _zoom;

    // Here is where the offset is happening
    _st.x += step(1., mod(_st.y,2.0)) * 0.5*iGlobalTime;
	// if(mod(_st.x,3.0) == mod(_st.y,3.0))
	// {
		
	// }
	 _st.y += step(1., mod(_st.x,2.0)) * 0.5*iGlobalTime;

    return fract(_st);
}

void main() {
	//coordinates in range [0,1]
    vec2 coord01 = gl_FragCoord.xy/iResolution;
	vec2 coordAspect = coord01;
	coordAspect.x *= iResolution.x / iResolution.y;
	coordAspect = brickTile(coordAspect,10.0);
	float zeuch = smoothBox(coordAspect, vec2(0.85),0.01);
	vec3 color = vec3(zeuch);
	
    gl_FragColor = vec4(color, 1.0);
}