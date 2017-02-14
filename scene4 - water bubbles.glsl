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
Material glassMat;
Material opaqueMat;
const int idGlass = 0;
const int idOpaque = 1;

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
	float glassBall = sSphere(point,vec3(-0.3,0.3,1),0.3);
	float a = sSphere(point, vec3(0, 0, 1.5), 0.3);
	float b = sSphere(point, vec3(0.3, 0.4, 1), 0.3);
	float dist = smin(a,b,0.1);
	dist = smin(dist,glassBall,0.1);
	return dist;
}

int idField(vec3 point)
{
	float glassBall = sSphere(point,vec3(-0.3,0.3,1),0.3);
	float a = sSphere(point, vec3(0, 0, 1.5), 0.3);
	float b = sSphere(point, vec3(0.3, 0.4, 1), 0.3);
	float opaque = smin(a,b,0.1);
	float dist = smin(opaque,glassBall,0.1);
	if(dist == glassBall) return idGlass;
	else return idOpaque;
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
	glassMat.col=vec4(0.2,0.2,0.2,0.1);
	glassMat.kSpecular = 0.8;
	glassMat.kDiffuse = 0.5;
	glassMat.kAmbient = 0.1;
	glassMat.shininess = 128;
	
	opaqueMat.col = vec4(0.3,0.3,0.3,1);
	opaqueMat.kSpecular = 0.2;
	opaqueMat.shininess = 128;
	opaqueMat.kAmbient =  1.0;
}

Material getMaterial(int id)
{
	switch(id)
	{
		case idGlass: return glassMat;
		case idOpaque: return opaqueMat;		
	}
}
vec4 shade(vec3 pointHit,vec3 rayDirection)
{
	vec3 normal = getNormal(pointHit, epsilon);
	
	vec3 ambientColor = vec3(0.1);
	
	//TODO: get from Material
	//mat = getMaterial(pointHit);
	vec3 color = vec3(0);
	int id = idField(pointHit);
	Material mat = getMaterial(id);
	
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
	return vec4(color,mat.col.a);
}
void main()
{
	initLights();
	initMaterials();
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

		vec4 color =shade(point,camDir);		
	
		gl_FragColor = color;
	}
	else
	{
		gl_FragColor = vec4(0, 0, 0, 1);
	}
}