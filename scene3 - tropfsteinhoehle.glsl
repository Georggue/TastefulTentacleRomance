// Modified version of the "Volcanic" shader by by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define YOSHI
uniform vec2 iResolution;
uniform vec3 iMouse;
uniform float iGlobalTime;
uniform sampler2D tex0;
uniform sampler2D tex1;
#include "/libs/Noise.glsl"
#include "/libs/noise3D.glsl"
#include "/libs/operators.glsl"

bool traceWater = true;
const int maxSteps = 256;
float maxT = 100.0;
vec4 texcube( sampler2D sam, vec3 p, vec3 n )
{
	vec4 x = texture2D( sam, p.yz );
	vec4 y = texture2D( sam, p.zx );
	vec4 z = texture2D( sam, p.xy );
	return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}

//=====================================================================

vec3 path( float time )
{
	vec3 path = vec3(cos(noise(0.8) * time) + sin(noise(0.64) * time), 0.8 * sin(0.77 * time), time);
	return path;
	
}


const mat3 m = mat3( -0.50,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float cave( vec3 p )
{

    float f = 1.15;
	float xGrowth = 1.0;
	float yGrowth = 1.0;
    #ifdef YOSHI
		xGrowth = 0.0002*iGlobalTime;
		yGrowth = 0.0003*iGlobalTime;		
	#endif
    vec3 s = 1.2 * vec3(sin(p.z * xGrowth*0.32), cos(p.z * 0.77*yGrowth), 1.0);    
    vec3 d = (path(p.z) - p) * s;
    float dist = length(d);
    f -= dist;
    
    vec3 stalactites = vec3(6.0, 0.15, 6.0);
	f += 0.7500 * clamp((0.5*snoise( stalactites * p )),-2,-0.15); p = m*p*3.06;
	// if(p.y >-1.0){
	// TODO: clamp as uniform for keyframes
		// f += 1.1500;
		    
		// f += 0.5000 * (0.5+snoise( stalactites * p )); p = m*p*3.06;
		// f += 0.2500 * gnoise( p ); p = m*p*2.02;
		// f += 0.1250 * noise( p ); p = m*p*2.04;
		// f += 0.0625 * gnoise( p ); p = m*p*2.01;
		// f += 0.03125 * noise( p ); 
	// }
	// else
	// {	
		// f +=0.7;
		// f += 0.7500 * clamp(0,1,(0.5+gnoise( stalactites * p ))); p = m*p*3.46;
		// f += 0.7500 * (0.5+gnoise( stalactites * p )); p = m*p*3.46;
		f += 0.5000 * gnoise( p ); p = m*p*1.02;
		f += 0.2500 * noise( p ); p = m*p*1.04;
		f += 0.1250 * gnoise( p ); p = m*p*1.01;
		f += 0.0625 * noise( p ); 
	// }
	
    return f;
}
float distWater(vec3 p)
{
	vec2 move = p.zx;
	move -= vec2(iGlobalTime * 0.5, iGlobalTime * 0.2);
	move *= 3;
	p.y += ((sin(move.x)+noise(iGlobalTime)) * (cos(move.y)+noise(iGlobalTime*0.4))) * .05; //waves!
	return sPlane(p,vec3(0,1,0),-1); 
}
float distField(vec3 p)
{
	if(!traceWater)
		return cave(p);
	return min(cave(p),distWater(p));
}
// Based on original by IQ.
float calculateAO(vec3 p, vec3 n){

    const float AO_SAMPLES = 5.0;
    float r = 0.0, w = 1.0, d;
    
    for (float i=1.0; i<AO_SAMPLES+1.1; i++){
        d = i/AO_SAMPLES;
        r += w*(d - distField(p + n*d));
        w *= 0.5;
    }
    
    return 1.0-clamp(r,0.0,1.0);
}


float raymarchTerrain( vec3 ro, vec3 rd ,float t, float maxT, int maxSteps,out int iterations)
{
	// float maxd = 30.0;
    // float t = 0.1;
	int i = 0;
    for(; i< maxSteps; i++ )
    {
	    float h = distField( ro + rd * t );
        if( h < (0.001 * t) || t > maxT ) break;
        t += (step(h, 1.) * .05 + 0.1) * h;
		
    }
	iterations = i;
    if( t>maxT ) t=-1.0;
    return t;
}

vec3 calcNormal( vec3 pos, float t )
{
    vec3 eps = vec3( max(0.02,0.001*t),0.0,0.0);
	return normalize( vec3(
           distField(pos+eps.xyy) - distField(pos-eps.xyy),
           distField(pos+eps.yxy) - distField(pos-eps.yxy),
           distField(pos+eps.yyx) - distField(pos-eps.yyx) ) );

}

//vec3 lig = normalize( vec3(-0.3,0.4,0.7) );

const int idCave = 0;
const int idWater = 1;

int calculateID(vec3 pos)
{
	float waterDist = distWater(pos);
	float caveDist = cave(pos);
	
	float dist = min(waterDist, caveDist);
	if(dist == waterDist) return idWater;
	else return idCave;
}

mat3 setCamera( vec3 ro, vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 ambientDiffuse(vec3 material, vec3 normal)
{
	vec3 ambient = vec3(0);

	vec3 lightDir = normalize(vec3(1, -1, 1));
	vec3 toLight = -lightDir;
	float diffuse = max(0, dot(toLight, normal));
	
	return ambient + diffuse * material;
}

vec3 localShade(int id, vec3 point)
{
	vec3 normal = getNormal(point, 0.01);
	switch(id)
	{
		case idCave:
		{
			return ambientDiffuse(texcube(tex0,point,normal), normal);
			break;
		}
		case idWater:
		{
			return ambientDiffuse(vec3(0,0.3,0.5), normal);
			break;
		}
		default:
			return -1;
	}
	
}

vec3 shade(int id, vec3 point, vec3 camDir)
{
	vec3 color = localShade(id, point);
	if(idWater == id)
	{
		vec3 normal = getNormal(point, 0.01);
		vec3 r = reflect(camDir, normal);
		int blah = 0;
		float t = raymarchTerrain(point, r, 0, 100, 100, blah);
		if(0 < t)
		{
			vec3 point = point + t * camDir;
			vec3 reflection = localShade(calculateID(point), point);
			color += 0.5*reflection;
		}
	}
	return color;
}

vec3 calculateColors(vec3 ro, vec3 rd, float t,vec3 pos, vec3 normal)
{
	vec3 color = vec3(-1);
	int id = calculateID(pos);
	color = shade(id,pos,rd);
	if(id == idWater)
	{
		traceWater = false; //ignore water plane in raymarch calculation
		int blah = 0;
		float waterT = raymarchTerrain(ro,rd,t,maxT,maxSteps, blah);
		float waterDepth = waterT - t;
		float weight = clamp(waterDepth * 0.5,0,1);
		vec3 newPoint = ro + waterT * rd;
		vec3 colorAtBottom = shade(calculateID(newPoint),newPoint,rd);
		color = mix(colorAtBottom,color,weight);		
		
	}
	// traceWater = true;  
	return color;
}
void main( )
{
	
	vec2 fragCoord = gl_FragCoord;
    vec2 q = fragCoord.xy / iResolution.xy;
	vec2 p = -1.0 + 2.0*q;
	p.x *= iResolution.x / iResolution.y;
	
	
    // camera	
	float off = step( 0.001, iMouse.z )*6.0*iMouse.x/iResolution.x;
	float time = off + 1.2 * iGlobalTime;
	vec3 ro = path( time-2.0 );
	vec3 ta = path( time+1.6 );
    
	ta.y *= 0.35 + 0.25*sin(0.09*time);
	// camera2world transform
    mat3 cam = setCamera( ro, ta, 0.0 );

    // ray    
	float r2 = p.x*p.x*0.32 + p.y*p.y;
	float shwobbliness = 1.0;
	#ifdef YOSHI
		shwobbliness *=2;
	#endif
    p *= (7.0-sqrt(37.5-11.5*r2))/(r2+shwobbliness); // cool shwobble effect
    vec3 rd = cam * normalize(vec3(p.xy,2.1));

    vec3 col =vec3(126,164,235)/255;
    
    // terrain	
	int iterations;
	float t = raymarchTerrain(ro, rd,0,maxT,maxSteps,iterations);
    if( t>0.0 )
	{
		vec3 pos = ro + t*rd;
		vec3 nor = calcNormal( pos, t );
	
        // lighting
		float bac = clamp( abs(dot( nor, rd)), 0.0, 1.0 );
        
        float ao = calculateAO(pos, nor);
	

		vec3 lin = ao * bac * vec3(0.7, 0.9, 1.0) / pow(t, 2.5);


        // surface shading/material	
      
		col = calculateColors(ro,rd,t,pos,nor);
		#ifdef YOSHI
			col.b += sin(iGlobalTime)*cos(iGlobalTime);
			col.r +=sin(iGlobalTime);
			col.g +=cos(iGlobalTime);
		#endif
		//col = vec3(1);
		col = lin * col;
    
		
    }
	

    // gamma	
	col = pow( clamp( col, 0.0, 1.0 ), vec3(0.465) );
	col += max(0., (exp(float(iterations)/float(maxSteps)))) * vec3(0.1);
	
	float gray = (col.r + col.r + col.b + col.g + col.g + col.g)/6;
	// float gray =  0.21 *col.r + 0.72 *col.g + 0.07 *col.b;
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
	float factor = clamp((t-tmin)/tmax,0,1);
	factor = clamp(factor, 0.0, 1.1);
	vec3 frontFogColor = vec3(184,134,11)/255;
	vec3 backFogColor =	 vec3(126,164,235)/255;
	vec3 fogColor = mix(frontFogColor,backFogColor,factor*1.1);
	col = mix(col.rgb, fogColor, factor);
	
	
    // contrast, desat, tint and vignetting	
	col = col*0.3 + 0.7*col*col*(3.0-2.0*col);
	col = mix( col, vec3(col.x+col.y+col.z)*0.33, 0.2 );
	col *= 1.3*vec3(1.06,1.1,1.0);
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
	gl_FragColor = vec4( col, 1.0 );
}