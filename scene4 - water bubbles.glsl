#version 330
#include "/libs/camera.glsl"
#include "/libs/operators.glsl"
#define PI 3.14159265358979323846
uniform vec2 iResolution;
uniform float iGlobalTime;
const float epsilon = 0.0001;
const int maxSteps = 640;
vec3 camPosBall;

const int maxRefractions = 4;
const int maxReflections = 4;

struct Raymarch
{
	vec4 pointHit;
	vec3 rayDirection;
	vec3 rayOrigin;
	float rayDist;
};
struct Material
{
	vec4 ambientColor;
	vec3 kSpecular;
	vec3 kDiffuse;
	float reflectiveIndex;
	float refractiveIndex;
	float transparency;
	int shininess;
	
};
Material glassMat;
Material opaqueMat;
Material goldMat;

const int idGlass = 0;
const int idOpaque = 1;
const int idGold = 2;
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
	// point = opRepeat(point,vec3(5));
	float glassBall = sSphere(point,vec3(-0.3,0.3,1),0.3);
	float glassBall2 = sSphere(point,vec3(0.3,-0.4,1),0.3);
	glassBall = opUnion(glassBall,glassBall2);
	float a = sSphere(point, vec3(0, 0, 1.5), 0.3);
	float b = sSphere(point, vec3(0.3, 0.4, 1), 0.3);
	float goldBall = sSphere(point, vec3(0.9,-0.3,1.2),.3);
	float dist = smin(a,b,0.1);
	dist = min(dist,goldBall);
	dist = min(dist,glassBall);
	return dist;
}

int idField(vec3 point)
{
	// point = opRepeat(point,vec3(5));
	float glassBall = sSphere(point,vec3(-0.3,0.3,1),0.3);
	float glassBall2 = sSphere(point,vec3(0.3,-0.4,1),0.3);
	glassBall = opUnion(glassBall,glassBall2);
	float a = sSphere(point, vec3(0, 0, 1.5), 0.3);
	float b = sSphere(point, vec3(0.3, 0.4, 1), 0.3);
	float goldBall = sSphere(point, vec3(0.9,-0.3,1.2),.3);
	float opaque = smin(a,b,0.1);
	float dist = min(opaque,glassBall);
	dist = min(dist,goldBall);
	if(dist == glassBall) return idGlass;
	else if(dist == goldBall) return idGold;
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
	rm.rayOrigin = rayOrigin;
	rm.rayDirection = rayDirection;
	float t = 0.0;
	
	//step along the ray 	
	
    for(int steps = 0; steps < maxSteps; ++steps)
    {
		//check how far the point is from the nearest surface
       	float dist = distField(point);
		
			//if we are very close
			if(abs(dist) < epsilon)
			{
				objectHit = true;
				break;
			}
			//not so close -> we can step at least dist without hitting anything
			t += abs(dist);
			//calculate new point
			point = rm.rayOrigin + t * rm.rayDirection; 			
		
    }
	
	if(objectHit)
	{
		rm.pointHit = vec4(point,1);
		
	}
	else
	{
		rm.pointHit = vec4(point,0);		
	}	
	rm.rayDist = t;
	return rm;
}

void initLights()
{
	lights[0].lightPos = vec3(0,0,-1);
	// lights[0].color = vec3(1,0,0);
	lights[0].color = vec3(1);
	lights[0].kIntensity = 0.3;
	lights[1].lightPos = vec3(10,10,-2);
	// lights[1].color = vec3(0,1,0);
	lights[1].color = vec3(1);
	lights[1].kIntensity = 0.2;
	lights[2].lightPos = vec3(-10,-10,-2);
	// lights[2].color = vec3(0,0,1);
	lights[2].color = vec3(1);
	lights[2].kIntensity = 0.3;
	lights[3].lightPos = vec3(10,-10,-2);
	// lights[3].color = vec3(1,1,0);
	lights[3].color = vec3(1);
	lights[3].kIntensity = 0.2;
}
void initMaterials()
{
	glassMat.ambientColor=vec4(0.2,0.2,0.2,0.1);
	glassMat.kSpecular = vec3(0.8);
	glassMat.kDiffuse = vec3(0.5);
	glassMat.shininess = 128;
	glassMat.refractiveIndex = 1.1;
	glassMat.reflectiveIndex = 0.8;
	glassMat.transparency = 1.0;
	
	opaqueMat.ambientColor = vec4(0.0,0.05,0.05,1);	
	opaqueMat.kDiffuse = vec3(0.4,0.5,0.5);
	// opaqueMat.kSpecular = vec3(0.04,0.7,0.7);	
	opaqueMat.kSpecular = vec3(0.04,0.7,0.7);	
	opaqueMat.shininess = int(.078125 * 128);	
	opaqueMat.refractiveIndex = 0.0;
	opaqueMat.reflectiveIndex = 0.05;
	opaqueMat.transparency = 0.0;
	
	goldMat.ambientColor=vec4(0.24725,0.1995,0.0745,1);
	goldMat.kDiffuse = vec3(0.75164,0.60648,0.22648);
	goldMat.kSpecular = vec3(0.628281,0.555802,0.366065);
	goldMat.shininess = int(0.4*128);
	goldMat.refractiveIndex = 0.0;	
	goldMat.reflectiveIndex = 0.6;
	goldMat.transparency = 0.0;
}

Material getMaterial(int id)
{
	switch(id)
	{
		case idGlass: return glassMat;
		case idOpaque: return opaqueMat;	
		case idGold: return goldMat;
	}
}
vec3 getAmbient()
{
	return vec3(0.0,.0,0.2);
}
vec4 shade(vec3 pointHit,vec3 rayDirection, out Material mat)
{
	//return vec4(vec3(1.,0.,0.),mat.ambientColor.a);
	
	vec3 normal = getNormal(pointHit, epsilon);
	
	vec3 backgroundColor = getAmbient();
	
	vec3 color = vec3(0);
	int id = idField(pointHit);
	mat = getMaterial(id);
	
	for(int i=0;i<4;i++)
	{
		//Ambient light
		vec3 partColor = mat.ambientColor.rgb * backgroundColor;
		//Diffuse
		float diffuse = max(0, dot(normalize(lights[i].lightPos - pointHit), normal));
		partColor += mat.ambientColor.rgb * diffuse*mat.kDiffuse;
		//Specular
		vec3 specular = lights[i].kIntensity * mat.kSpecular * ((mat.shininess + 2)/(2*PI)) * pow(max(0,dot(reflect(normalize(lights[i].lightPos - pointHit),normal),rayDirection)),mat.shininess);
		partColor += specular;
		
		color += partColor*lights[i].color;
	}	
	return vec4(color,mat.ambientColor.a);
}
vec4 calcTransparency(vec3 pointHit, vec3 rayDirection,vec4 originalColor, float alpha)
{
	//0.6 = sphereDiameter, massive hack. In theory: go into object, find other side, exit object, trace again. In practice? WTF
	vec3 newOrigin = pointHit+((0.6+epsilon)*rayDirection);
	//We need to go DEEPER!
	Raymarch transparencyMarch = rayMarch(newOrigin,rayDirection);
					
	if(transparencyMarch.pointHit.a == 1.0)
	{
		// material *= calculateColors(FRIDOLIN,transparencyMarch.pointHit.xyz)*material.a;
		Material mat;
		vec4 col = shade(transparencyMarch.pointHit.xyz,rayDirection,mat);
		originalColor.rgb = ( originalColor.rgb * originalColor.a) + ((1- originalColor.a)*col.rgb);
	}
	
	return originalColor;
}
vec4 calcTransparency(vec3 pointHit, vec3 rayDirection,float alpha)
{
		// float wallThickness = epsilon;
	    int maxTransparencyIterations = 3;
		vec4 col = vec4(0);
		
		for(int i=0;i<maxTransparencyIterations;i++)
			{			
				vec3 newPos = pointHit + epsilon*rayDirection;			
				Raymarch transparencyMarch = rayMarch(newPos,rayDirection);
				
				if(transparencyMarch.pointHit.a == 1)
				{
					Material dummy;
					pointHit = transparencyMarch.pointHit.xyz;
					vec4 tempCol = shade(pointHit,rayDirection,dummy);
					col.xyz += tempCol.xyz*alpha;
				}			
			}
			return col;
}
vec4 calcReflection(vec3 firstHit, vec3 firstRayDir)
{
		// int maxReflections = 2;
		vec3 pointHit = firstHit + (getNormal(firstHit,epsilon)*epsilon);
		Material mat = getMaterial(idField(pointHit));
		vec4 col = vec4(0);
		
		for(int i=0;i<maxReflections;i++)
		{			
			
			vec3 normal = getNormal(pointHit,epsilon);
			vec3 rayOrigin = pointHit;
			vec3 rayDirection = reflect(firstRayDir,normal);
			Raymarch reflectionRay =rayMarch(rayOrigin,rayDirection);
						
			if(reflectionRay.pointHit.a == 1.0)
			{
				Material hitMaterial;
				vec3 shadedColor = shade(reflectionRay.pointHit.xyz,rayDirection,hitMaterial).xyz;
				col.xyz += (shadedColor * mat.reflectiveIndex);
				// col.xyz*=mat.kSpecular;
			}
			else
			{
				// return vec4(getAmbient()*0.3,1);		
				i=maxReflections;
			}
			pointHit = reflectionRay.pointHit.xyz +  (getNormal(reflectionRay.pointHit.xyz,epsilon)*epsilon);
		}
		return col;
}
float fresnel(vec3 rayDirection, vec3 normal, float refractionIndex)
{
	float kr = 0;
	float cosi = clamp(dot(rayDirection, normal),-1, 1); 
    float etai = 1, etat = refractionIndex; 
    if (cosi > 0) {
		float tmp;
		tmp = etai;
		etai = etat;
		etat = tmp;		
	} 
    // Compute sini using Snell's law
    float sint = etai / etat * sqrt(max(0.0, 1 - cosi * cosi)); 
    // Total internal reflection
    if (sint >= 1) { 
        kr = 1; 
    } 
    else { 
        float cost = sqrt(max(0.f, 1 - sint * sint)); 
        cosi = abs(cosi); 
        float Rs = ((etat * cosi) - (etai * cost)) / ((etat * cosi) + (etai * cost)); 
        float Rp = ((etai * cosi) - (etat * cost)) / ((etai * cosi) + (etat * cost)); 
        kr = (Rs * Rs + Rp * Rp) / 2; 
    } 
    // As a consequence of the conservation of energy, transmittance is given by:
    // kt = 1 - kr;
	return kr;
}
vec4 calcRefraction(vec3 firstHit, vec3 firstRayDir, float refractiveIndex)
{
		vec4 col = vec4(0);
		vec3 refractionColor = vec3(0); 
        // compute fresnel		
		vec3 hitPoint = firstHit;
		vec3 rayDir = firstRayDir;
		for(int i=0;i<maxRefractions;i++)
		{
			vec3 normal = getNormal(hitPoint,epsilon);
			// float kr = fresnel(rayDir, normal, refractiveIndex); 
			bool outside = dot(rayDir,normal) < 0; 		
			vec3 bias = vec3(0);
			// compute refraction if it is not a case of total internal reflection
			// if (kr < 1) { 
				vec3 refractionDirection = normalize(refract(rayDir, normal, !outside ? refractiveIndex : 1/refractiveIndex)); 
				vec3 refractionRayOrig = outside ? hitPoint - bias : hitPoint + bias; 
				Raymarch refractionRay = rayMarch(refractionRayOrig,refractionDirection);
				if(refractionRay.pointHit.a == 1)
				{
					Material dummy;
					refractionColor = shade(refractionRay.pointHit.xyz,refractionDirection,dummy).xyz;
				}        
				else
				{	
					refractionColor = vec3(1,0,0);
				}   
			// } 
			// vec4 reflectionCol = calcReflection(firstHit,firstRayDir);
			
			col.xyz += refractionColor.xyz ; 
			hitPoint = refractionRay.pointHit.xyz;
			rayDir = refractionDirection;
		}
	
       
	return col;
}
mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}
vec3 refractMe(vec3 I, vec3 N, float ior)
{
	float cosi = clamp(dot(I, N),-1, 1);
	float etai = 1, etat = ior;
	vec3 n = N;
	if (cosi < 0) { cosi = -cosi; } 
	else 
	{
		float tmp;
		tmp = etai;
		etai = etat;
		etat = tmp;		
		n= -N; 
	}
	float eta = etai / etat;
	float k = 1 - eta * eta * (1 - cosi * cosi);
	return (k < 0.) ? vec3(0.) : (eta * I + (eta * cosi - sqrt(k)) * n);
} 
vec4 render(Raymarch rm)
{	
	vec4 hitPoint = rm.pointHit;
	vec3 rayDir = rm.rayDirection;
	vec4 color = vec4(0.,0.,0.,1.);	
	for(int i=0;i<maxRefractions;i++)
	{
		if(hitPoint.a == 1.0)
		{
			Material mat = getMaterial(idField(hitPoint.xyz));
			if(mat.transparency < epsilon)
			{	
				color.xyz += shade(hitPoint.xyz,rayDir,mat).xyz + calcReflection(hitPoint.xyz,rayDir.xyz).rgb;					
				break;
			}
			 //else
				 //color.xyz += vec3(0.,0.,1.);
			
			
			vec3 normal = getNormal(hitPoint.xyz,epsilon); 
			bool outside = dot(rayDir,normal) < 0;
			
			vec3 refractionDirection = refractMe(rayDir, outside ? normal : -normal, mat.refractiveIndex); 
			vec3 bias = 2.*epsilon*normal;
			vec3 refractionRayOrig = outside ? hitPoint.xyz - bias : hitPoint.xyz + bias; 
			Raymarch refractionRay = rayMarch(refractionRayOrig, refractionDirection);
			
		
			hitPoint = refractionRay.pointHit;
			rayDir = refractionDirection;
		}	
		else if(i == maxRefractions-1)
		{
			color.xyz += getAmbient();
		}
		
	}
	return color+ calcReflection(rm.pointHit.xyz,rm.rayDirection.xyz);
	
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
	float t = 0.0;
	//step along the ray 
	Raymarch rm;
	
	rm = rayMarch(camP,camDir);
	
	vec4 col = render(rm);
	//Pointlights with different colors, phong lighting
	
	
	gl_FragColor = col;

}