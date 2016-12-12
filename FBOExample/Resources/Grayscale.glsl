#version 430 core

uniform sampler2D image;
uniform float iGlobalTime;
uniform vec2 superGeilerParameter;

in vec2 uv;

float grayScale(vec3 color)
{
	return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
}

void main() 
{
	vec3 image = texture(image, uv).rgb;
	image = vec3(grayScale(image));
	gl_FragColor = vec4(image, 1.0);
}