float maxComponent(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

float uBox(vec3 point, vec3 center, vec3 b )
{
  return length(max(abs(point - center) - b, vec3(0.0)));
}

float sBox(vec3 point, vec3 center, vec3 b) {
	vec3 d = abs(point - center) - b;
	return length(max(d, vec3(0))) + maxComponent(min(d, vec3(0)));
}

float sSphere(vec3 point, vec3 center, float radius) {
    return length(point - center) - radius;
}

float uSphere(vec3 point, vec3 center, float radius) {
    return max(0.0, sSphere(point, center, radius));
}

vec3 rotateX(vec3 point, float angle)
{
	mat3 rot = mat3(1., 0., 0.,
					0., cos(angle), -sin(angle),
					0., sin(angle), cos(angle));
	return rot * point;
}

vec3 rotateY(vec3 point, float angle)
{
	mat3 rot = mat3(cos( angle ), 0.0, -sin( angle ),
					0.0,           1.0, 0.0,
					sin( angle ), 0.0, cos( angle ));
	return rot * point;
}

vec3 rotateZ(vec3 point, float angle)
{
	mat3 rot = mat3(cos( angle ), -sin( angle ), 0.0,
					sin( angle ),  cos( angle ), 0.0,
					0.0,           0.0, 1.0);
	return rot * point;
}

///http://www.iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float opUnion(float dist1, float dist2)
{
	return min(dist1, dist2);
}

float opIntersection(float dist1, float dist2)
{
	return max(dist1, dist2);
}

float opDifference(float dist1, float dist2)
{
	return max(dist1, -dist2);
}

//repeat the given coordinate point every interval c[axis]
vec3 opRepeat(vec3 point, vec3 c)
{
    return mod(point, c) - 0.5 * c;
}

vec3 opRepeatCentered(vec3 point, vec3 interval) {
	vec3 c = floor((point + interval*0.5)/interval);
	return mod(point + interval*0.5, interval) - interval*0.5;
}

float distField(vec3 point);

//normal by numerical gradient
vec3 getNormal(vec3 point, float delta)
{
	//get points a little bit to each side of the point
	vec3 right = point + vec3(delta, 0.0, 0.0);
	vec3 left = point + vec3(-delta, 0.0, 0.0);
	vec3 up = point + vec3(0.0, delta, 0.0);
	vec3 down = point + vec3(0.0, -delta, 0.0);
	vec3 behind = point + vec3(0.0, 0.0, delta);
	vec3 before = point + vec3(0.0, 0.0, -delta);
	//calc difference of distance function values == numerical gradient
	vec3 gradient = vec3(distField(right) - distField(left),
		distField(up) - distField(down),
		distField(behind) - distField(before));
	return normalize(gradient);
}
vec3 hash31(float p) {
    //  3 out, 1 in... DAVE HOSKINS
   vec3 p3 = fract(vec3(p) * vec3(.1031,.11369,.13787));
   p3 += dot(p3, p3.yzx + 19.19);
   return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}
vec3 opTwist( vec3 p, float a )
{
    float  c = cos(a*p.y*3.14159265);
    float  s = sin(a*p.y*3.14159265);
    mat2   m = mat2(c,-s,s,c);
    
    p.xz = m*p.xz;
    return vec3(p);
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}
