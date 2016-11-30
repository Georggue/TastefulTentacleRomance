#version 330

#include "libs/camera.glsl"
#include "libs/hg_sdf.glsl"
#include "libs/operators_unser.glsl"
#define FRIEDA false
#define FRIDOLIN true
uniform vec2 iResolution;
uniform float iGlobalTime;
uniform sampler2D tex0;
uniform sampler2D tex1;

const float epsilon = 0.01;
const int maxSteps = 128;
const float glowRadius = 0.1;

struct BodyBoobiesNeckHeadNoseEyes
{
	float body;
	float boobies;
	float head;
	float nose;
	float neck;
	float eyes;
	float totalDist;
	vec3 col;
};
struct Tentacles
{
	float tentacles;
	vec3 col;
};
struct Eyeballs{
	float eyeballs;
	vec3 col;
};
struct Lips{
	float lips;
	vec3 col;
};
struct Halo
{
	float halo;
	vec3 col;
};
struct Dress
{
	float dress;
	vec3 col;
};
struct Shirt
{
	float shirt;
	vec3 col;
};
struct Jacket
{
	float jacket;
	vec3 col;
};
struct BeltRibbon
{
	float belt;
	float ribbon;
	vec3 col;
};
struct Monocle
{
	float monocle;
	vec3 monocleFrameCol;
	float monocleGlass;
	vec3 monocleGlassCol;
};
struct Octopus
{	
	BodyBoobiesNeckHeadNoseEyes body;
	Tentacles tentacles;
	Eyeballs eyeballs;
	Lips lips;
	Halo halo;
	Shirt shirt;
	Dress dress;
	Jacket jacket;
	BeltRibbon beltRibbon;
	Monocle monocle;
	
	float dist;
	vec3 col;
};
struct Kelp
{
	float dist;
	vec3 col;
	bool kelpHit;
}kelp;
Octopus frieda;
Octopus fridolin;
float worldDist;
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
		vec3 p2 = rotateY( point, (TAU *i /8.0)+iGlobalTime*4 /*+ 0.04 * rr*/  );
		// p2.y -= 3 * rr * exp2(-10.0 * rr);
		vec3 p3 = rotateZ(p2, PI / 2);
		float cylinder = fCapsule(p3, factor * (1 - rr * 0.5),10.0);
		dist = min( dist, cylinder );
	}
	return dist;
}
Octopus setOctoColors(Octopus monster, bool isMale)
{
	if(isMale == FRIEDA)
	{	
		monster.body.col = vec3(236,179,255)/255;
		monster.tentacles.col = vec3(151,69,178)/255;
		monster.eyeballs.col = vec3(230,255,213)/255;
		monster.lips.col = vec3(151,69,178)/255;
		monster.halo.col = vec3(1);
		monster.dress.col = vec3(1);
		monster.beltRibbon.col = vec3(116,178,153)/255;
	}else if(isMale == FRIDOLIN)
	{
		monster.body.col = vec3(117,151,222)/255;
		monster.tentacles.col = vec3(77,99,145)/255;
		monster.eyeballs.col = vec3(50,64,94)/255;
		monster.lips.col = vec3(158,109,99)/255;
		monster.dress.col = vec3(18,26,43)/255;
		monster.shirt.col = vec3(1);
		monster.jacket.col = vec3(29,42,69)/255;
		monster.beltRibbon.col = vec3(76,94,40)/255;
		monster.monocle.monocleFrameCol = vec3(255,254,91)/255;
		monster.monocle.monocleGlassCol = vec3(143,234,250)/255;
	}
	return monster;
}
Octopus distMonster(vec3 point, bool isMale,Octopus monster)
 {
	if(isMale == FRIEDA)
	{
		// point.z -= 1.0;
		point.x -=3;
		// tentacles FRIEDA
		vec3 tentaclePoint = point;		
		float move = dot(point.yz, point.yz) * 0.2 * (sin(iGlobalTime));
		tentaclePoint.x += move;
		monster.tentacles.tentacles = distTentacle(tentaclePoint, 0.05);
		
		// body FRIEDA
		vec3 bodyPos = point;
		vec3 ribbonBeltPoint = point;
		monster.body.body = fSphere(bodyPos, 0.3);
		vec3 boxPoint = bodyPos;
		boxPoint.y += .5;
		float cutBodySphere = fBox(boxPoint,vec3(.95,.45, .95));
		monster.body.body = opDifference(monster.body.body, cutBodySphere);
		bodyPos.y -= 0.1;
		
		// boobies FRIEDA
		vec3 boobyPoint = bodyPos;
		float moveboobs = dot(boobyPoint.yz, boobyPoint.yz) * 0.051 * (sin(3*iGlobalTime))+0.05;
		boobyPoint.z += 0.19 ;
		boobyPoint.x +=.125;
		boobyPoint.y-=.175;
		boobyPoint.y +=moveboobs;
		float sphereBooby1 = fSphere(boobyPoint,0.05);	
		 // boobyPoint.x -=.1;	 	 
		 boobyPoint = bodyPos;
		 boobyPoint.z += 0.19;
		 boobyPoint.y-=.175;
		 boobyPoint.x -=0.125;
		 boobyPoint.y +=moveboobs;
		 float sphereBooby2 = fSphere(boobyPoint,0.05);	
		 monster.body.boobies = opUnion(sphereBooby1,sphereBooby2);
			 
		// neck FRIEDA
		bodyPos.y -=0.2;
		bodyPos = rotateZ(bodyPos,sin(PI / 2 * iGlobalTime)/4);
		bodyPos.y -=0.3;
		monster.body.neck = fCylinder(bodyPos, 0.01,0.3);
		
		// head FRIEDA
		vec3 headPos = point;
		headPos = rotateZ(headPos,sin(PI / 2 * iGlobalTime)/4);
		headPos.y -= 0.85;
		monster.body.head = fSphere(headPos, 0.2);	
		
		// halo FRIEDA
		vec3 haloPos = headPos;
		haloPos.y -=.25;
		haloPos.y += -0.01 + sin(iGlobalTime*3)*0.05;
		monster.halo.halo = fTorus(haloPos,.0125,.2);
		
		headPos.y -=.02;		
		headPos.x -=.1;
		headPos.z +=0.2;
		
		// eyes and eyeballs FRIEDA
		float sphereEye1 = fSphere(headPos, 0.09);	
		vec3 eyeballPoint = headPos;
		eyeballPoint.x +=.022;
		eyeballPoint.y-=.01;
		eyeballPoint.x +=sin(iGlobalTime*4)/35;
		eyeballPoint.y +=cos(iGlobalTime*4)/35;
		float sphereEyeFilled1 = fSphere(eyeballPoint,0.03);
		headPos.x +=.2;
		 
		float sphereEye2 = fSphere(headPos, 0.09);
		eyeballPoint = headPos;
		eyeballPoint.y-=.01;
		eyeballPoint.x -=0.022;
		 
		eyeballPoint.x +=cos(iGlobalTime*4)/35;
		eyeballPoint.y +=sin(iGlobalTime*4)/35;
		float sphereEyeFilled2 = fSphere(eyeballPoint,0.02);	 
			
		monster.body.eyes = opUnion(sphereEye1,sphereEye2);
		monster.eyeballs.eyeballs = opUnion(sphereEyeFilled1,sphereEyeFilled2);

		// nose	FRIEDA
		headPos.x -= .1;
		headPos.y += .05;
		headPos.z += .01;
		vec3 nosePoint = headPos;
		nosePoint.y += sin(2*iGlobalTime)*0.015;
		monster.body.nose = fSphere(nosePoint,0.01);
		headPos.y += .12;
		monster.body.head = opUnion(monster.body.head,monster.body.nose);
		
		vec3 ribbonPoint = headPos;
		
		headPos.z -=.125;
		headPos.z +=.075;
		headPos.y +=.06;
		headPos = rotateZ(headPos,PI / 2);
		
		// lips FRIEDA
		vec3 lipPoint1 = headPos;
		vec3 lipPoint2 = headPos;
		lipPoint2.z -=0.025;
		headPos = opCheapBend(headPos);
		lipPoint1.x -= .055;
		lipPoint1.x += sin(2*iGlobalTime)*0.01;
		float upperLip = fCapsule(lipPoint1,0.0025,0.025);
		lipPoint2.x -= 0.04;
		float lowerLip = fCapsule(lipPoint2,0.0025,0.035);
		monster.lips.lips = opUnion(upperLip,lowerLip);
		
		// dress FRIEDA
		monster.dress.dress = smin(monster.body.body, monster.body.neck, 0.2);
		monster.dress.dress = smin(monster.dress.dress, monster.body.boobies, 0.1);
		monster.dress.dress = smin(monster.dress.dress, monster.tentacles.tentacles, 0.1);
		monster.dress.dress *= 0.5;
		bodyPos.y -= .35;
		
		float sphereCutNeck = fSphere(bodyPos, 0.5);
		monster.dress.dress = opDifference(monster.dress.dress, sphereCutNeck);
		
		float torusCutTentacles = fTorus(tentaclePoint,.44,1.27);
		monster.dress.dress = opDifference(monster.dress.dress, torusCutTentacles);
		
		float sphereDress = fSphere(tentaclePoint, 0.85);
		tentaclePoint.y -= .445;
		float boxCutSphereDress = fBox(tentaclePoint,vec3(.95,.45, .95));
			
		sphereDress = opDifference(sphereDress, boxCutSphereDress);
		tentaclePoint.y +=.85;
		boxCutSphereDress = fBox(tentaclePoint,vec3(.95,.4, .95));
		sphereDress = opDifference(sphereDress, boxCutSphereDress);
		monster.dress.dress = smin(monster.dress.dress, sphereDress, 0.1);
		monster.dress.dress = opDifference(monster.dress.dress, boxCutSphereDress);
		
		// belt FRIEDA
		tentaclePoint.x -= move;
		tentaclePoint.z += .022;
		tentaclePoint.y -= .525;
		monster.beltRibbon.belt = fTorus(tentaclePoint, .0001, .315);
		
		// ribbon belt FRIEDA
		ribbonBeltPoint.z += .35;
		ribbonBeltPoint.y -= .12;
		float sphereRibbon = fSphere(ribbonBeltPoint, 0.003);
		monster.beltRibbon.belt = opUnion(monster.beltRibbon.belt, sphereRibbon);
		ribbonBeltPoint.x -= .05;
		ribbonBeltPoint = rotateZ(ribbonBeltPoint, PI/2);
		float coneRibbon = fCone(ribbonBeltPoint, 0.03, 0.04);
		monster.beltRibbon.belt = opUnion(monster.beltRibbon.belt, coneRibbon);
		ribbonBeltPoint = rotateZ(ribbonBeltPoint, -PI/2);
		ribbonBeltPoint.x += .1;
		ribbonBeltPoint = rotateZ(ribbonBeltPoint, -PI/2);
		coneRibbon = fCone(ribbonBeltPoint, 0.03, 0.04);
		monster.beltRibbon.belt = opUnion(monster.beltRibbon.belt, coneRibbon);
		
		// ribbon head FRIEDA
		vec3 ribbonPoint2;
		ribbonPoint.z -= .445;
		ribbonPoint.y -= .25;
		ribbonPoint2 = ribbonPoint;
		sphereRibbon = fSphere(ribbonPoint, 0.005);
		ribbonPoint.x -= .05;
		ribbonPoint = rotateZ(ribbonPoint, PI/2);
		coneRibbon = fCone(ribbonPoint, 0.04, 0.05);
		monster.beltRibbon.ribbon = opUnion(sphereRibbon, coneRibbon);
		ribbonPoint2.x += .05;
		ribbonPoint = rotateZ(ribbonPoint2, -PI/2);
		coneRibbon = fCone(ribbonPoint, 0.04, 0.05);
		monster.beltRibbon.ribbon = opUnion(monster.beltRibbon.ribbon, coneRibbon);
		
	}else if(isMale == FRIDOLIN)
	{
	 // tentacles FRIDOLIN
		vec3 tentaclePoint = point;		
		float move = dot(point.yz, point.yz) * 0.2 * (sin(iGlobalTime));
		tentaclePoint.x += move;
		monster.tentacles.tentacles = distTentacle(tentaclePoint, 0.09);
		
		// body FRIDOLIN
		vec3 bodyPos = point;
		vec3 ribbonBeltPoint = point;
		
		monster.body.body = fSphere(bodyPos, 0.4);
		vec3 boxPoint = bodyPos;
		boxPoint.y += .5;
		float cutBodySphere = fBox(boxPoint,vec3(.95,.45, .95));
		monster.body.body = opDifference(monster.body.body, cutBodySphere);
		bodyPos.y -= 0.1;
		
		// neck FRIDOLIN
		bodyPos.y -=0.2;
		bodyPos = rotateZ(bodyPos,sin(PI / 2 * iGlobalTime)/4);
		bodyPos.y -=0.3;
		monster.body.neck = fCylinder(bodyPos, 0.03,0.2);
		
		// head FRIDOLIN
		vec3 headPos = point;
		headPos.y -= .2;
		headPos = rotateZ(headPos,sin(PI / 2 * iGlobalTime)/4);
		headPos.y -= 0.85;
		monster.body.head = fSphere(headPos, 0.5);	
		
		vec3 hatPos = headPos;
				
		headPos.y -=.02;		
		headPos.x -=.1;
		headPos.z +=0.5;
		
		// eyes and eyeballs FRIDOLIN
		float sphereEye1 = fSphere(headPos, 0.09);	
		vec3 eyeballPoint = headPos;
		eyeballPoint.x +=.022;
		eyeballPoint.y-=.01;
		eyeballPoint.x +=sin(iGlobalTime*4)/35;
		eyeballPoint.y +=cos(iGlobalTime*4)/35;
		float sphereEyeFilled1 = fSphere(eyeballPoint,0.03);
		headPos.x +=.2;
		 
		//monocle
		vec3 monoclePoint = headPos;
		monoclePoint.x-=0.2;
		monoclePoint.y +=0.025;
		monoclePoint.z +=0.055;
		monoclePoint = rotateX(monoclePoint,PI / 2);
		monster.monocle.monocle = fDisc(monoclePoint,0.03);
		float monocleCutOut = fSphere(monoclePoint,0.04);
		monster.monocle.monocle = opDifference(monster.monocle.monocle,monocleCutOut);
		monster.monocle.monocleGlass = fDisc(monoclePoint,0.028);
		
		float sphereEye2 = fSphere(headPos, 0.09);
		eyeballPoint = headPos;
		eyeballPoint.y-=.01;
		eyeballPoint.x -=0.022;
		 
		eyeballPoint.x +=cos(iGlobalTime*4)/35;
		eyeballPoint.y +=sin(iGlobalTime*4)/35;
		float sphereEyeFilled2 = fSphere(eyeballPoint,0.02);	 
			
		monster.body.eyes = opUnion(sphereEye1,sphereEye2);
		monster.eyeballs.eyeballs = opUnion(sphereEyeFilled1,sphereEyeFilled2);

		// nose	FRIDOLIN
		headPos.x -= .1;
		headPos.y += .15;
		vec3 nosePoint = headPos;
		nosePoint.y += sin(2*iGlobalTime)*0.015;
		nosePoint = rotateX(nosePoint, PI/12);
		monster.body.nose = fCapsule(nosePoint,0.1, 0.03);
		headPos.y += .12;
		monster.body.head = opUnion(monster.body.head,monster.body.nose);
		
		vec3 ribbonPoint = headPos;
		
		headPos.z -= 0.09;
		headPos.y +=.12;
		headPos = rotateZ(headPos,PI / 2);
		
		// lips FRIDOLIN
		vec3 lipPoint1 = headPos;
		vec3 lipPoint2 = headPos;
		lipPoint2.z -=0.012;
		headPos = opCheapBend(headPos);
		lipPoint1.x -= .055;
		lipPoint1.x += sin(2*iGlobalTime)*0.01;
		float upperLip = fCapsule(lipPoint1,0.0025,0.035);
		lipPoint2.x -= 0.04;
		float lowerLip = fCapsule(lipPoint2,0.0025,0.045);
		monster.lips.lips = opUnion(upperLip,lowerLip);
		
		// shirt FRIDOLIN
		monster.shirt.shirt = smin(monster.body.body, monster.body.neck, 0.2);
		monster.shirt.shirt *= 0.5;
		bodyPos.y -= .35;
		float sphereCutNeck = fSphere(bodyPos, .6);
		monster.shirt.shirt = opDifference(monster.shirt.shirt, sphereCutNeck);
		
		// trousers & jacket FRIDOLIN
		// trousers (--> dress) FRIDOLIN 
		monster.dress.dress = smin(monster.tentacles.tentacles, monster.body.body, .1);
		monster.dress.dress *= .45;
		tentaclePoint.y -= move;
		tentaclePoint.y -= .43;
		float boxCutTrousers = fBox(tentaclePoint, vec3(.5, .3, .5));
		monster.dress.dress = opDifference(monster.dress.dress, boxCutTrousers);
		tentaclePoint.y += .43;
		float torusCutTentacles = fTorus(tentaclePoint, .5, 1.45);
		monster.dress.dress = opDifference(monster.dress.dress, torusCutTentacles);
		
		// jacket FRIDOLIN
		monster.jacket.jacket = smin(monster.body.body,monster.body.neck,0.2);
		monster.jacket.jacket = smin(monster.jacket.jacket,monster.tentacles.tentacles,0.2);
		monster.jacket.jacket *= .4;
		bodyPos.y += .35;
		bodyPos.z += .26;
		float boxCutJacket = fBox(bodyPos, vec3(.08,.45,.25));
		monster.jacket.jacket = opDifference(monster.jacket.jacket, boxCutJacket);
		
		// bow tie (--> ribbon) FRIDOLIN
		vec3 ribbonPoint2;
		ribbonPoint.z -= .3;
		ribbonPoint.y += .39;
		ribbonPoint2 = ribbonPoint;
		float sphereRibbon = fSphere(ribbonPoint, 0.005);
		ribbonPoint.x -= .05;
		ribbonPoint = rotateZ(ribbonPoint, PI/2);
		float coneRibbon = fCone(ribbonPoint, 0.04, 0.05);
		monster.beltRibbon.ribbon = opUnion(sphereRibbon, coneRibbon);
		ribbonPoint2.x += .05;
		ribbonPoint = rotateZ(ribbonPoint2, -PI/2);
		coneRibbon = fCone(ribbonPoint, 0.04, 0.05);
		monster.beltRibbon.ribbon = opUnion(monster.beltRibbon.ribbon, coneRibbon);
		
		// hat (--> together with ribbon, same color) FRIDOLIN
		hatPos.x -= .25;
		hatPos.y -= .59;
		hatPos.y += -0.01 + sin(iGlobalTime*3)*0.05;
		hatPos = rotateZ(hatPos, -PI/8);
		float hat = fCylinder(hatPos, 0.15,0.1);
		hatPos.y += .09;
		float brim = fCylinder(hatPos, 0.2, 0.01);
		hat = opUnion(hat, brim);
		monster.beltRibbon.ribbon = opUnion(monster.beltRibbon.ribbon, hat);
	}
	// color
	monster = setOctoColors(monster,isMale);
	return monster;
} 
vec4 calculateColors(bool isMale, vec3 uv)
{
	Octopus monster;
	vec4 col = vec4(1);
	if(isMale == FRIEDA)
	{
		monster = frieda;
		
		if(monster.eyeballs.eyeballs < monster.body.body && monster.eyeballs.eyeballs < monster.body.head)
		{
			col = vec4(monster.eyeballs.col,1);			
		}
		else if(monster.lips.lips < monster.body.body && monster.lips.lips < monster.body.head && monster.lips.lips < monster.tentacles.tentacles)
		{
			col = vec4(monster.lips.col,1);
		}
		else if(monster.beltRibbon.belt < monster.dress.dress)
		{
			col = vec4(monster.beltRibbon.col,1);			
		}
				else if(monster.beltRibbon.ribbon < monster.body.totalDist)
		{
			col = vec4(monster.beltRibbon.col,1);			
		}
		
		else if(monster.dress.dress < monster.body.totalDist)
		{
			col = vec4(monster.dress.col,1);
			col.rgb += (texture2D(tex1, uv.xy*2).x)*.25;
					
		}
		else if(monster.tentacles.tentacles < monster.body.body)
		{
			col =vec4(monster.tentacles.col,1);
			col.rgb += (texture2D(tex0, uv.xy*4).x)*0.25;
		
		}
		else if(monster.halo.halo < monster.body.body && monster.halo.halo < monster.body.head)
		{
			col = vec4(monster.halo.col,1);		
		}		
		else
		{
			col =  vec4(monster.body.col,1);
			col.rgb += (texture2D(tex0, uv.xy*4).x)*0.25;
		
		
		}
	}
	else
	{
		monster= fridolin;
		
		if(monster.eyeballs.eyeballs < monster.body.body && monster.eyeballs.eyeballs < monster.body.head && monster.eyeballs.eyeballs < monster.monocle.monocle && monster.eyeballs.eyeballs < monster.monocle.monocleGlass)
		{
			col = vec4(monster.eyeballs.col,1);
		}
		else if(monster.monocle.monocle < monster.body.head && monster.monocle.monocle < monster.eyeballs.eyeballs && monster.monocle.monocle < monster.monocle.monocleGlass)
		{
			col = vec4(monster.monocle.monocleFrameCol,1);
		}else if(monster.monocle.monocleGlass < monster.body.head && monster.monocle.monocleGlass < monster.eyeballs.eyeballs && monster.monocle.monocleGlass<monster.monocle.monocle)
		{
			col = vec4(monster.monocle.monocleGlassCol,0.1);
		}
		else if(monster.lips.lips < monster.body.body && monster.lips.lips < monster.body.head && monster.lips.lips < monster.tentacles.tentacles)
		{
			col = vec4(monster.lips.col,1);			
		}				
		else if(monster.dress.dress < monster.body.totalDist)
		{
			col = vec4(monster.dress.col,1);
			col.rgb += (texture2D(tex1, uv.xy*2).x)*0.25;
			
		}
		else if(monster.tentacles.tentacles < monster.body.body)
		{
			col = vec4(monster.tentacles.col,1);
			col.rgb += (texture2D(tex0, uv.xy*4).x)*0.25;
		
		}
		else if(monster.jacket.jacket < monster.shirt.shirt && monster.jacket.jacket < monster.body.totalDist && monster.jacket.jacket < monster.beltRibbon.ribbon)
		{
			col = vec4(monster.jacket.col,1);
			col.rgb += (texture2D(tex1, uv.xy*2).x)*0.25;
		
		}
		else if(monster.shirt.shirt < monster.body.body && monster.shirt.shirt < monster.body.head && monster.shirt.shirt < monster.beltRibbon.ribbon) 
		{
			col = vec4(monster.shirt.col,1);			
		}		
		
		else if(monster.beltRibbon.ribbon < monster.body.totalDist)
		{
			col = vec4(monster.beltRibbon.col,1);			
		}
		else
		{
			col =  vec4(monster.body.col,1);
			col.rgb += (texture2D(tex0, uv.xy*4).x)*0.25;
			
		}
	}
	return col;
}
Octopus calculateOctopusStuff(Octopus octoInput, bool isMale)
{
	Octopus monster = octoInput;
	if(isMale == FRIEDA)
	{
		float dist = smin(octoInput.body.body,octoInput.body.neck,0.2);	
		dist = smin(dist, octoInput.body.head,0.1);
		dist = opUnion(dist,octoInput.halo.halo);
		dist = smin(dist,octoInput.body.boobies,0.1);
		dist = smin(dist,octoInput.tentacles.tentacles,0.1);
		dist = opDifference(dist,octoInput.body.eyes);
		dist = opUnion(dist,octoInput.eyeballs.eyeballs);
		dist = opUnion(dist,octoInput.lips.lips);
		monster.body.totalDist = dist;
		dist = opUnion(dist,octoInput.dress.dress);
		dist = opUnion(dist, octoInput.beltRibbon.belt);
		dist = opUnion(dist, octoInput.beltRibbon.ribbon);
		monster.dist = dist;
	
	}
	else if(isMale == FRIDOLIN)
	{		
		float dist = smin(octoInput.body.body,octoInput.body.neck,0.2);	
		dist = smin(dist, octoInput.body.head,0.1);
		dist = smin(dist,octoInput.tentacles.tentacles,0.1);
		dist = opDifference(dist,octoInput.body.eyes);
		dist = opUnion(dist,octoInput.eyeballs.eyeballs);
		dist = opUnion(dist,octoInput.monocle.monocle);
		dist = opUnion(dist,octoInput.monocle.monocleGlass);
		dist = opUnion(dist,octoInput.lips.lips);
		monster.body.totalDist = dist;
		dist = opUnion(dist, octoInput.shirt.shirt);
		dist = opUnion(dist,octoInput.dress.dress);
		dist = opUnion(dist, octoInput.jacket.jacket);
		dist = opUnion(dist, octoInput.beltRibbon.ribbon);
		
		monster.dist = dist;
		
	}
	
	return monster;
}
Kelp distKelp(vec3 point)
{
	Kelp kelp;
	// point.y = saturate(point.y * sin(iGlobalTime));
	point = vec3(point.x+sin(iGlobalTime+point.y*.2)*.5, point.y, point.z);
	
	point = opRepeat(point, vec3(4.2,0,4.2));
	point = opTwist(point,floor(hash31(42).y*10)/40);
	float cylinder = udRoundBox(point, vec3(0.025,1.25,.025), 0.00125);
	kelp.dist = udRoundBox(point, vec3(mix(.1, .3, hash31(42).x), 40., 0.01), .005);
	kelp.col = vec3(91,140,121)/255;
	return kelp;
}

vec3 globalCol;
float distField(vec3 point)
{
	float plane = fPlane(point, vec3(0, 1, 0), 0.1);
	kelp = distKelp(point);
	kelp.kelpHit = false;
	frieda = distMonster(point, FRIEDA, frieda); // frieda
	frieda = calculateOctopusStuff(frieda, FRIEDA);
	fridolin = distMonster(point, FRIDOLIN, fridolin); // fridolin
	fridolin = calculateOctopusStuff(fridolin, FRIDOLIN);
	
	// float d1 = min(plane, kelp.dist);

	// if(kelp.dist < plane && kelp.dist < frieda.dist)
	// {		
		// kelp.kelpHit = true;
	// }
	float d1=0;
	worldDist = fridolin.dist;
	d1 = min(d1,frieda.dist);
	d1 = min(d1,fridolin.dist);
	
	return  frieda.dist;
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

void main()
{	
	vec3 camP = calcCameraPos();
	camP.z += -3.0;
	camP.y += 0.3;
	vec3 camDir = calcCameraRayDir(80.0, gl_FragCoord.xy, iResolution);
	
	//start point is the camera position
	vec3 point = camP; 	
	bool objectHit = false;
	float t = 0.0;
	
	//step along the ray 
	float glowCol = 0.0;
	
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
        point = camP + t * camDir;
    }

	vec4 color = vec4(1, 1, 1,1);
	if(objectHit)
	{	
		vec4 material;
		if(frieda.dist < fridolin.dist && frieda.dist < worldDist)
		{
			material = calculateColors(FRIEDA,point);
		}else if(fridolin.dist < frieda.dist && fridolin.dist < worldDist)
		{
			material = calculateColors(FRIDOLIN,point);
		}
		else
		{				
			material = vec4(vec3(97,101,145)/255,1);
		}		
		
		if(kelp.kelpHit){
			material = vec4(kelp.col,1);
		}
				
		// vec3 normal = getNormal(point, 0.01);
		// vec3 lightDir = normalize(vec3(0, -1.0, 1));
		// vec3 toLight = -lightDir;
		// float diffuse = max(0, dot(toLight, normal));
		// vec3 ambient = vec3(0.1);
		// color = ambient + diffuse * material;
		color.rgba = ambientOcclusion(point, 0.2 , 20) * material.rgba;
	}
	
	// float gray = (color.r + color.r + color.b + color.g + color.g + color.g)/6;
	// color.r += 0.1*(1-gray);
	// color.b += 0.3*gray;
	
	// fog
	// float tmax = 10.0;
	// float factor = t/tmax;
	// factor = clamp(factor, 0.0, 1.1);
	// color = vec4(mix(color.rgb, (vec3(126,164,235)/255), factor),color.a);
	
	// vignette
	// float innerRadius = .45;
	// float outerRadius = .65;
	// float intensity = .7;
	// vec4 vignetteColor = vec4(vec3(37,39,68)/255,1);
	// vec2 relativePosition = gl_FragCoord.xy / iResolution -.5;
	// relativePosition.y *= iResolution.x / iResolution.y;
	// float len = length(relativePosition);
	// float vignetteOpacity = smoothstep(innerRadius, outerRadius, len) * intensity;
	// color = mix(color, vignetteColor, vignetteOpacity);
	
	gl_FragColor = vec4(color);
}