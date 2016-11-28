uniform float iCamPosX;
uniform float iCamPosY;
uniform float iCamPosZ;
uniform float iCamRotX;
uniform float iCamRotY;
uniform float iCamRotZ;

vec3 calcCameraPos()
{
	return vec3(iCamPosX, iCamPosY, iCamPosZ);
}

// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void rotateAxis(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

vec3 calcCameraRayDir(float fov, vec2 fragCoord, vec2 resolution) 
{
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / resolution.x;
	vec2 p = tanFov * (fragCoord * 2.0 - resolution.xy);
	vec3 rayDir = normalize(vec3(p.x, p.y, 1.0));
	rotateAxis(rayDir.yz, iCamRotX);
	rotateAxis(rayDir.xz, iCamRotY);
	rotateAxis(rayDir.xy, iCamRotZ);
	return rayDir;
}