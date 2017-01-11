#version 330

#include "libs/camera.glsl"
#include "libs/hg_sdf.glsl"
#include "libs/operators_unser.glsl"
#include "libs/Noise.glsl"

uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D tex0; // octopus body
uniform sampler2D tex1; // dress

const float epsilon = 0.01;
const int maxSteps = 128;
const float glowRadius = 0.1;

struct Raymarch
{
	vec4 pointHit;
	float rayDist;
};
struct Wine 
{
	float wine;
	float liquid;
	float label;
	vec3 labelCol;
	vec3 liquidCol;
	vec3 col;
};
float worldDist;
float tableDist;



vec3 opCheapBend( vec3 p )
{
    float c = cos(20.0*p.y/3);
    float s = -sin(20.0*p.y/3);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    return q;
}
float distTentacle(vec3 point, float factor)
{
	float rr = dot(point.xz, point.xz);
	float dist = 10e7;
	for(int i = 0; i < 4; ++i)
	{
		vec3 p2 = rotateY( point, (TAU *i /8.0)+iGlobalTime + 0.5*sin(iGlobalTime) * rr  );
		// p2 = rotateX(point, (TAU * i/8.0));
		// p2.y -= 3 * rr * exp2(-10.0 * rr);
		vec3 p3 = rotateZ(p2, PI / 2);
		float cylinder = fCapsule(p3, factor * (1 - rr * 0.5),10.0);
		dist = min( dist, cylinder );
	}
	return dist;
}


vec3 globalCol;

vec2 rotate2D(vec2 coord, float angle)
{
    mat2 rot =  mat2(cos(angle),-sin(angle), sin(angle),cos(angle));
    return rot * coord;
}

float lines(in vec2 pos, float b){
    float scale = 10.0;
    pos *= scale;
    return smoothstep(0.0,
                    .5+b*.5,
                    abs((sin(pos.x* PI)+b*2.0))*.5);
}


vec3 wood(vec2 coord)
{
	coord = rotate2D(coord, gnoise(coord)+.25*gnoise(coord)); // rotate the space
    float weight = lines(coord, 0.9); // draw lines
	vec2 coord2 = coord.xy;
	coord2 = rotate2D(coord2,gnoise(coord2));
	float weight2 = lines(coord2,0.1);
	vec3 valA = mix( 	vec3(139,115,85)/255,  	vec3(205,170,125)/255, weight);
	vec3 valB = mix( 	vec3(139,115,85)/255,  	vec3(205,170,125)/255, weight2);
	return mix(valA,valB,0.5)	;
}

vec4 calcCol(vec3 coord)
{
	if(tableDist < worldDist)
	{
		return vec4(wood(coord.zx*3),1);
	}else{
		return vec4(1,1,1,1);
	}
	
}

float distTable(vec3 p)
{
	p.y -=1;
	
	vec3 tablePoint = p;
	tablePoint.y +=0.35;
	float table = fCylinder(tablePoint,9.0/10,0.1/10);
	
	p = rotateX(p,PI/2);
	
	table = smin(table,udRoundBox( (vec3(0.3 + cos(p.z) * 0.3,0.4 + cos(p.z) * 0.2,-0.6) + p) , vec3(0.02,0.05,0.2), 0.02), 0.05);
	table = smin(table,udRoundBox( (vec3(-0.3 - cos(p.z) * 0.3,0.4 + cos(p.z) * 0.2,-0.6) + p) , vec3(0.02,0.05,0.2), 0.02),0.05);
	table = smin(table,udRoundBox( (vec3(-0.3 - cos(p.z) * 0.3,-0.4 - cos(p.z) * 0.2,-0.6) + p) , vec3(0.02,0.05,0.2), 0.02),0.05);
	table = smin(table,udRoundBox( (vec3(0.3 + cos(p.z) * 0.3,-0.4 - cos(p.z) * 0.2,-0.6) + p) , vec3(0.02,0.05,0.2), 0.02),0.05);
		
	return table;
}
float distField(vec3 point)
{
	float plane = fPlane(point, vec3(0, 1, 0), 0.1);
	float table = distTable(point);
	tableDist = table;
	
	
	float d1 = plane;


	worldDist = d1;
	// d1 = min(d1,frieda.dist);
	d1 = min(d1,table);
	
	return  d1;
}

float ambientOcclusion(vec3 point, float delta, int samples)
{
	vec3 normal = getNormal(point, 0.0001);
	normal = getNormal(point + epsilon*normal,0.0001);
	float occ = 0;
	for(int i = 1; i < samples; ++i)
	{	
		occ += (1.0/exp2(i)) * (i * delta - distField(point + i * delta * normal));
	}
	occ = clamp(occ, 0, 1);
	return 1 - occ;
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
// Raymarch TransparencyMarch(vec3 RayOrigin, vec3 RayDir, int iterations)
void main()
{	
	vec3 camP = calcCameraPos();
	camP.z += -3.0;
	camP.y += 0.3;
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	
	Raymarch rm = rayMarch(camP,camDir);

	vec4 color = vec4(0, 0, 0,1);
	vec4 material = calcCol(rm.pointHit.xyz);
				
		// vec3 normal = getNormal(rm.pointHit.rgb, 0.01);
		// vec3 lightDir = normalize(vec3(0, -1.0, 1));
		// vec3 toLight = -lightDir;
		// float diffuse = max(0, dot(toLight, normal));
		// vec3 ambient = vec3(0.1);
		// color.rgb = ambient + diffuse * material.rgb;
		color.rgba = ambientOcclusion(rm.pointHit.xyz, 0.2 , 20) * material.rgba;
	
	
	
	
	gl_FragColor = vec4(color);
}