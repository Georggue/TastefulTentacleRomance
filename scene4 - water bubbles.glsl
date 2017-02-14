#version 330
#include "/libs/camera.glsl"
#include "/libs/operators.glsl"
#define PI 3.14159268
uniform vec2 iResolution;
uniform float iGlobalTime;
const float epsilon = 0.0001;
const int maxSteps = 128;
vec3 camPosBall;

struct Raymarch
{
	vec4 pointHit;
	float rayDist;
};
struct Material
{
	vec4 col;
	float kSpecular;
	float kDiffuse;
	float kAmbient;
	int shininess;
};
struct Light
{
	vec3 lightPos;
	vec3 color;
	float kIntensity;
};
Light lights[4];
//M = center of sphere
//P = some point in space
// return normal of sphere when looking from point P
vec3 sphereNormal(vec3 M, vec3 P)
{
	return normalize(P - M);
}

vec3 normalField(vec3 point){
	// point = -opRepeat(point, vec3(3, 3, 3));
	return sphereNormal(point, vec3(0, 0, 0));
}
float distSpheres(vec3 point)
{
	float a = sSphere(point, vec3(0, 0, 0), 0.3);
	float b = sSphere(point, vec3(0.3, 0.4, 0), 0.3);
	return smin(a,b,0.1);
}
float distField(vec3 point)
{	
	return distSpheres(point);
}
Raymarch rayMarch(vec3 rayOrigin, vec3 rayDirection)
{
//start point is the camera position
	vec3 point = rayOrigin; 	
	bool objectHit = false;
	Raymarch rm;
	float t = 0.0;
	
	//step along the ray 	
	
    for(int steps = 0; steps < maxSteps; ++steps)
    {
		//check how far the point is from the nearest surface
       	float dist = distField(point);
		 			
		//if we are very close
        if(epsilon > dist)
        {
			objectHit = true;
            break;
        }
		//not so close -> we can step at least dist without hitting anything
        t += dist;
		//calculate new point
        point = rayOrigin + t * rayDirection;
    }
	
	if(objectHit)
	{
		rm.pointHit = vec4(point,1);
		rm.rayDist = t;
		return rm;
	}
	else
	{
		rm.pointHit = vec4(point,0);
		rm.rayDist = t;
		return rm;
	}	
}
  /*
    vec3 lightPos;
	vec3 color;
	float kIntensity;
  */
void initLights()
{
	lights[0].lightPos = vec3(-10,10,-2);
	lights[0].color = vec3(1,0,0);
	lights[0].kIntensity = 0.3;
	lights[1].lightPos = vec3(10,10,-2);
	lights[1].color = vec3(0,1,0);
	lights[1].kIntensity = 0.2;
	lights[2].lightPos = vec3(-10,-10,-2);
	lights[2].color = vec3(0,0,1);
	lights[2].kIntensity = 0.3;
	lights[3].lightPos = vec3(10,-10,-2);
	lights[3].color = vec3(1,1,0);
	lights[3].kIntensity = 0.2;
}
void initMaterials()
{
	//TODO: Add materials
	/*Material mat;
	mat.col = vec4(0.3,0.3,0.3,1);
	mat.kSpecular = 0.2;
	mat.shininess = 128;
	mat.kAmbient =  1.0;*/
}
vec3 shade(vec3 pointHit,vec3 rayDirection)
{
	vec3 normal = getNormal(pointHit, epsilon);
	
	vec3 ambientColor = vec3(0.1);
	
	//TODO: get from Material
	//mat = getMaterial(pointHit);
	vec3 color = vec3(0);
	Material mat;
	mat.col = vec4(0.3,0.3,0.3,1);
	mat.kSpecular = 0.2;
	mat.shininess = 128;
	mat.kAmbient =  1.0;
	for(int i=0;i<4;i++)
	{
		//Ambient light
		vec3 partColor = mat.col.rgb * mat.kAmbient * ambientColor;
		//Diffuse
		float diffuse = max(0, dot(normalize(lights[i].lightPos - pointHit), normal));
		partColor += mat.col.rgb * diffuse;
		//Specular
		float specular = lights[i].kIntensity * mat.kSpecular * ((mat.shininess + 2)/(2*PI)) * pow(max(0,dot(reflect(normalize(lights[i].lightPos - pointHit),normal),rayDirection)),mat.shininess);
		partColor += specular;
		
		color += partColor*lights[i].color;
	}
	return color;
}
void main()
{
	initLights();
	vec3 camP = calcCameraPos() ;//+ vec3(0, 0, -1);
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	camPosBall = camP;
	//start point is the camera position
	vec3 point = camP; 	
	bool objectHit = false;
	float t = 0.0;
	//step along the ray 
	Raymarch rm;
	rm = rayMarch(camP,camDir);
   
	if(rm.pointHit.a == 1)
	{
	//Pointlights with different colors, phong lighting
	point = rm.pointHit.xyz;
	vec3 color =shade(point,camDir);
	
	
		gl_FragColor = vec4(color, 1);
	}
	else
	{
		gl_FragColor = vec4(0, 0, 0, 1);
	}
}