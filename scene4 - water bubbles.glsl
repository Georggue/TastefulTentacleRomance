#version 330
// #include "/libs/camera.glsl"
#include "/libs/operators.glsl"
#include "/libs/hg_sdf.glsl"
// #define PI 3.14159265358979323846
uniform vec2 iResolution;
uniform float iGlobalTime;
uniform float lightCol1;
uniform float lightCol2;
uniform float lightCol3;
uniform float lightCol4;
uniform float angle;
const float epsilon = 0.0001;
const int maxSteps = 256;
vec3 camPosBall;

const int maxRefractions = 8;
const int maxReflections = 1 ;

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
Material floorMat;
Material pearlMat;
const int idGlass = 0;
const int idOpaque = 1;
const int idGold = 2;
const int idFloor = 3;
const int idClam = 4;
const int idPearl = 5;
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
vec3 rotateX(vec3 point, float angle)
{
	mat3 rot = mat3(1., 0., 0.,
					0., cos(angle), -sin(angle),
					0., sin(angle), cos(angle));
	return rot * point;
}

// Das ist meine Mupfel!
float distClam(vec3 point)
{
	float angleMupfel = 1 + sin(iGlobalTime+3);
	// vec3 clamPointUpper = vec3(0,-0.3,0);
	// clamPointUpper.z+=0.25;
	vec3 upperClamPoint = point;
	upperClamPoint = rotateX(upperClamPoint,PI);
	upperClamPoint.z +=.55;
	upperClamPoint.y -=.2;
	upperClamPoint = rotateX(upperClamPoint,angleMupfel);
	upperClamPoint.z -=.55;
	upperClamPoint.y-=.1;
	
	float upperHalf = fSphere(upperClamPoint,0.5);	
	float upperHalfCut1 = fSphere(upperClamPoint,0.49);	
	upperClamPoint.x-=.6;
	float upperHalf2 = fSphere(upperClamPoint,0.5);
	float upperHalfCut2 = fSphere(upperClamPoint,0.49);
	upperHalf = smin(upperHalf,upperHalf2,0.7);
	float upperHalfCut = smin(upperHalfCut1,upperHalfCut2,0.7);
	upperClamPoint.y-=.35;
	float cube = fBox(upperClamPoint, vec3(2.,0.5,2.));
	upperHalf = max(upperHalf,-cube);
	upperHalf = max(upperHalf,-upperHalfCut);
	
	vec3 clamPointLower = vec3(0);
	float lowerHalf = sSphere(point,clamPointLower,0.5);
	float lowerHalfCut1 = sSphere(point,clamPointLower,0.49);
	clamPointLower.x+=.6;
	float lowerHalf2 = sSphere(point,clamPointLower,0.5);
	float lowerHalfCut2 = sSphere(point,clamPointLower,0.49);
	// clamPoint.x-=.6;
	
	lowerHalf = smin(lowerHalf,lowerHalf2,0.7);	
	float lowerHalfCut = smin(lowerHalfCut1,lowerHalfCut2,0.7);
	clamPointLower.y+=.4;
	cube  = sBox(point, clamPointLower, vec3(2.,0.6,2.));
	lowerHalf = max(lowerHalf,-cube);
	lowerHalf = max(lowerHalf,-lowerHalfCut);
	// float lowerHalf = sSphere(point,vec3(0,0,0),0.5);
	
	return min(upperHalf,lowerHalf);
}
float glassBallSize = 0.1;
float distSpheres(vec3 point)
{
	vec3 babyBubblePoint = point;
	babyBubblePoint.x += 1.;
	babyBubblePoint.y += sin(point.z - iGlobalTime * 2.0) * cos(point.x - iGlobalTime) * .25; //waves!
	// babyBubblePoint.z += 3.0;
	babyBubblePoint = opRepeat(babyBubblePoint,vec3(2,0,2));
	float babyGold = sSphere(babyBubblePoint,vec3(0),0.1);
	
	// point+=vec3(2.5,0,0);
	point = opRepeat(point,vec3(6,0,0));
	vec3 clamPoint = point;
	// clamPoint = opRepeat(clamPoint,vec3(5,0,0));
	vec3 clamPoint2 = point;
	clamPoint2.x -= 0.3;
	clamPoint2 = rotateY(clamPoint2,PI);
		clamPoint2.x += 0.3;
	clamPoint2.z -=2.;

	
	
	float plane = fPlane(point,vec3(0,1,0),1);
	
	vec3 glassBallPoint = point;
	glassBallPoint.x += 2.;
	glassBallPoint.z += 1.;
	
	float scale = 2 / (3 - cos(0.5*2*iGlobalTime));
	float x = scale * cos(0.5*iGlobalTime);
	float y = scale * sin(0.5*2*iGlobalTime) / 2;
	float glassBall = sSphere(glassBallPoint+vec3(0,y,x),vec3(0),.5);
	
	vec3 glassBallPoint2 = point;
	glassBallPoint2.x += 2.;
	glassBallPoint2.z += 1.;
	float glassBall2 = sSphere(glassBallPoint2+vec3(0,-y,-x),vec3(0),.5);
	glassBall = smin(glassBall,glassBall2,0.3);

	float goldPearl = sSphere(clamPoint+vec3(0,-0.3+sin(iGlobalTime)/10,0), vec3(0.25,-0.3,0),.3);
	float goldPearl2 = sSphere(clamPoint2+vec3(0,-0.3+sin(iGlobalTime)/10,0), vec3(0.25,-0.3,0.),.3);
	
	float dist = goldPearl;
	dist = min(dist,goldPearl2);
	dist = min(dist,glassBall);
	dist = min(dist,plane);
	float clam =distClam(clamPoint);
	float clam2 =distClam(clamPoint2);
	dist = min(dist,clam);
	dist = min(dist,clam2);	
	dist = min(dist,babyGold);
	return dist;
}

int idField(vec3 point)
{
	vec3 babyBubblePoint = point;
	babyBubblePoint.x += 1.;
	babyBubblePoint.y += sin(point.z - iGlobalTime * 2.0) * cos(point.x - iGlobalTime) * .25; //waves!
	// babyBubblePoint.z += 3.0;
	babyBubblePoint = opRepeat(babyBubblePoint,vec3(2,0,2));
	float babyGold = sSphere(babyBubblePoint,vec3(0),0.1);
	// point+=vec3(2.5,0,0);
	point = opRepeat(point,vec3(6,0,0));
	vec3 clamPoint = point;
	
	vec3 clamPoint2 = point;
	clamPoint2.x -= 0.3;
	clamPoint2 = rotateY(clamPoint2,PI);
	clamPoint2.x += 0.3;
	clamPoint2.z -=2.;
	
	
	vec3 offset = vec3(10,0,0);
	float plane = fPlane(point,vec3(0,1,0),1);

	vec3 glassBallPoint = point;
	glassBallPoint.x += 2.;
	glassBallPoint.z += 1.;
	
	float scale = 2 / (3 - cos(0.5*2*iGlobalTime));
	float x = scale * cos(0.5*iGlobalTime);
	float y = scale * sin(0.5*2*iGlobalTime) / 2;
	float glassBall = sSphere(glassBallPoint+vec3(0,y,x),vec3(0),.5);
	
	vec3 glassBallPoint2 = point;
	glassBallPoint2.x += 2.;
	glassBallPoint2.z += 1.;
	float glassBall2 = sSphere(glassBallPoint2+vec3(0,-y,-x),vec3(0),.5);
	glassBall = smin(glassBall,glassBall2,0.3);
	
	
	
	float goldPearl = sSphere(clamPoint+vec3(0,-0.3+sin(iGlobalTime)/10,0), vec3(0.25,-0.3,0),.3);
	float goldPearl2 = sSphere(clamPoint2+vec3(0,-0.3+sin(iGlobalTime)/10,0), vec3(0.25,-0.3,0.),.3);
	float dist = goldPearl;
	dist = min(dist,goldPearl2);
	dist = min(dist,glassBall);
	dist = min(dist,plane);
	float clam =distClam(clamPoint);
	float clam2 =distClam(clamPoint2);
	dist = min(dist,clam);
	dist = min(dist,clam2);
	dist = min(dist,babyGold);
	if(dist == glassBall) return idGlass;
	else if(dist== babyGold) return idGold;
	else if(dist == goldPearl || dist == goldPearl2  ) return idPearl;
	else if(dist == plane) return idFloor;
	else if(dist == clam || dist == clam2) return idClam;
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

void initLights(vec3 movement)
{
	lights[0].lightPos = vec3(0,0,-2)+movement;
	// lights[0].color = vec3(lightCol1,0,0);
	lights[0].color = vec3(1);
	lights[0].kIntensity = 1.;
	
	lights[1].lightPos = vec3(10,10,-2)+movement;
	// lights[1].color = vec3(0.3,0,0);
	lights[1].color = vec3(1);
	lights[1].kIntensity = 1.0;
	
	lights[2].lightPos = vec3(-10,-10,-2)+movement;
	lights[2].color = vec3(0,0.3,0);
	// lights[2].color = vec3(1);
	lights[2].kIntensity = 0.6;
	
	lights[3].lightPos = vec3(10,-10,-2)+movement;
	lights[3].color = vec3(0,0,0.3);
	// lights[3].color = vec3(1);
	lights[3].kIntensity = 0.5;
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
	
	opaqueMat.ambientColor = vec4(0.4,0.01,0.65,1);	
	opaqueMat.kDiffuse = vec3(0.4,0.5,0.5);
	// opaqueMat.kSpecular = vec3(0.04,0.7,0.7);	
	opaqueMat.kSpecular = vec3(0.04,0.7,0.7);	
	opaqueMat.shininess = int(.078125 * 128);	
	opaqueMat.refractiveIndex = 0.0;
	opaqueMat.reflectiveIndex = 0.05;
	opaqueMat.transparency = 0.0;
	
	goldMat.ambientColor= vec4(0.24725,0.1995,0.0745,1);
	goldMat.kDiffuse = vec3(0.75164,0.60648,0.22648);
	goldMat.kSpecular = vec3(0.628281,0.555802,0.366065);
	goldMat.shininess = int(0.1*128);
	goldMat.refractiveIndex = 0.0;	
	goldMat.reflectiveIndex = 0.1;
	goldMat.transparency = 0.0;
	
	pearlMat.ambientColor=vec4(vec3(236,179,255)/512,1);
	pearlMat.kDiffuse = vec3(0.75164,0.60648,0.22648);
	pearlMat.kSpecular = vec3(0.628281,0.555802,0.366065);
	pearlMat.shininess = int(0.4*128);
	pearlMat.refractiveIndex = 0.0;	
	pearlMat.reflectiveIndex = 0.6;
	pearlMat.transparency = 0.0;
	
	floorMat.ambientColor = vec4(0.5,0.5,.5,1.);
	floorMat.kDiffuse=vec3(0.1);
	floorMat.kSpecular =vec3(0.0);
	floorMat.shininess = 1;
	floorMat.refractiveIndex = 0.0;
	floorMat.reflectiveIndex = 0.0;
	floorMat.transparency = 0.0;
}

Material getMaterial(int id)
{
	switch(id)
	{
		case idGlass: return glassMat;
		case idOpaque: return opaqueMat;	
		case idGold: return goldMat;
		case idFloor: return floorMat;		case idClam: return opaqueMat;
		case idPearl: return pearlMat;
	}
}
vec3 getAmbient()
{
	return vec3(0.3,.3,0.3);
}
float calcDiffuse(vec3 lightDir,vec3 normal)
{
	return max(0, dot(normalize(lightDir), normal));
}

float calcSpecular(vec3 lightDir, vec3 rayDir,vec3 normal, int shininess)
{
	return ((shininess + 2)/(2*PI)) * pow(max(0,dot(reflect(normalize(lightDir),normal),rayDir)),shininess);
}

float softshadow(vec3 origin, vec3 dir, float mint, float maxt, float k )
{
    float res = 1.0;
    for( float t = mint; t < maxt; )
    {
        float h = distField(origin + dir * t);
        if( h < epsilon )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
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
		float shadow = max(0.2,softshadow(pointHit,lights[i].lightPos-pointHit,0.1,20.,2.));	
		//Diffuse
		float diffuse = shadow*calcDiffuse(lights[i].lightPos - pointHit, normal);
		partColor += mat.ambientColor.rgb * diffuse*mat.kDiffuse;
		//Specular
		vec3 specular = lights[i].kIntensity * mat.kSpecular * calcSpecular(lights[i].lightPos-pointHit,rayDirection,normal,mat.shininess);
		partColor += specular;
		
		color += partColor*lights[i].kIntensity*lights[i].color;
				
	}	
	return vec4(color,mat.ambientColor.a);
}

vec4 calcReflection(vec3 firstHit, vec3 firstRayDir)
{		
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

// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void rotateAxis(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

vec3 calcCameraRayDir(float fov, vec2 fragCoord, vec2 resolution,vec3 cameraAngles) 
{
	float tanFov = tan(fov / 2.0 * 3.14159 / 180.0) / resolution.x;
	vec2 p = tanFov * (fragCoord * 2.0 - resolution.xy);
	vec3 rayDir = normalize(vec3(p.x, p.y, 1.0));
	rotateAxis(rayDir.yz, cameraAngles.x);
	rotateAxis(rayDir.xz, cameraAngles.y);
	rotateAxis(rayDir.xy, cameraAngles.z);
	return rayDir;
}
void main()
{
	
	initMaterials();
	vec3 camP =  vec3(1, 1.5, -1) + iGlobalTime*vec3(-1,0,0)/2;
	initLights(iGlobalTime*vec3(-1,0,0)/2);
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution,vec3(-PI/12,-PI/2,0));
	camPosBall = camP;
	//start point is the camera position
	vec3 point = camP; 	
	float t = 0.0;
	//step along the ray 
	Raymarch rm;
	
	rm = rayMarch(camP,camDir);
	
	vec4 col = render(rm);
	//Pointlights with different colors, phong lighting
	float gray = (col.r + col.r + col.b + col.g + col.g + col.g)/6;
	col.r += 0.1*(1-gray);
	col.b += 0.3*gray;
	
		// fog
	// float tmax = 20.0;
	// float factor = t/tmax;
	// factor = clamp(factor, 0.0, 1.1);
	// col = mix(col.rgb, (vec3(255,0,0)/255), factor);
	
	// fog
	float tmax = 10.0;
	float tmin = 5.5;
	float factor = clamp((rm.rayDist-tmin)/tmax,0,1);
	factor = clamp(factor, 0.0, 1.1);
	vec3 frontFogColor = vec3(184,134,11)/255;
	vec3 backFogColor =	 vec3(126,164,235)/255;
	vec3 fogColor = mix(frontFogColor,backFogColor,factor*1.1);
	col = vec4(mix(col.rgb, fogColor, factor),1);
	
	
    // contrast, desat, tint and vignetting	
	col = col*0.3 + 0.7*col*col*col;
	col = vec4(mix( col.rgb, vec3(col.x+col.y+col.z)*0.33, 0.2 ),1);
	col *= vec4(1.3*vec3(1.06,1.1,1.0),1);
	// col *= 0.4 + 0.5*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
	// vignette
	// float innerRadius = .45;
	// float outerRadius = .65;
	// float intensity = .7;
	// vec4 vignetteColor = vec4(vec3(37,39,68)/255,1);
	// vec2 relativePosition = gl_FragCoord.xy / iResolution -.5;
	// relativePosition.y *= iResolution.x / iResolution.y;
	// float len = length(relativePosition);
	// float vignetteOpacity = smoothstep(innerRadius, outerRadius, len) * intensity;
	// col = mix(col, vignetteColor, vignetteOpacity);
	vec2 relativePosition = gl_FragCoord.xy / iResolution -.5;
	vec2 center = vec2(.5, .5); // center of screen
	float distCenterUV = distance(center,relativePosition)*1.3;
	float innerVig = 0.38;
	float outerVig = .6;	
	float intensity = .7;
	vec4 vignetteColor = vec4(vec3(37,39,68)/255,1);
	// vec3 vignetteColor = vec3(0);
	float len = length(relativePosition);
	float vignetteOpacity = smoothstep(innerVig, outerVig, len) * intensity;
	col = mix(col, vignetteColor, vignetteOpacity);	
	
	gl_FragColor = col;

}