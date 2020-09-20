#version 300 es
//settings precision is required (sometimes...)
precision mediump float; //max float is 2^14=16384
//precision mediump sampler2D;
//precision highp float; //max float is 2^62
//precision mediump sampler3D; //setting (any) precision is required for some reason
//precision highp sampler3D;

#define s(a, b, x) smoothstep(a, b, x)
#define rot(a) mat2(cos(a + PI*0.5*vec4(0,1,3,0)))
#define PI 3.14159265359

vec3 raydir(vec2 uv, vec3 ro, vec3 lookAt) {
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(cross(forward, up));
    vec3 upward = cross(right, forward);
    float fov = 1.0;
    float dist = 0.5 / tan(fov*0.5);
    return normalize(forward*dist + right*uv.x + upward*uv.y);
}

float clamp01(float x) {return clamp(x, 0.0, 1.0);}
vec2 clamp01(vec2 x) {return clamp(x, 0.0, 1.0);}
vec3 clamp01(vec3 x) {return clamp(x, 0.0, 1.0);}

float max0(float x ) {
    return max(0.0, x);
}

float invmix(float a, float b, float t) {
	return clamp01((t-a)/(b-a));
}

//const float PI = 4.0*atan(1.0); //3.14159265359;
float gammaexpand(float u) {
    return (u <= 0.04045) ? u/12.92 : pow((u+0.055)/1.055, 2.4);
}
float gammacompress(float u) {
    return (u <= 0.0031308) ? 12.92*u : pow(1.055*u, 0.4166667)-0.055;
}

//rgb - srgb
vec3 srgb2rgb(vec3 srgb) {
    return vec3(gammaexpand(srgb.x), gammaexpand(srgb.y), gammaexpand(srgb.z));
}
vec3 rgb2srgb(vec3 rgb) {
    return vec3(gammacompress(rgb.x), gammacompress(rgb.y), gammacompress(rgb.z));
}

vec3 tonemap(vec3 color, float exposure) {
    return vec3(1.0) - exp(-color * exposure);
}

vec3 fresnelSchlick(float VH, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - VH, 5.0);
}

float DistributionGGX(float NH, float roughness) {
  float a = roughness*roughness;
  float a2 = a*a;
  float r = (NH * NH * (a2 - 1.0) + 1.0);
  return a2 / max(PI * r * r, 0.001);
}

float GeometrySchlickGGX(float NV, float roughness) {
  float r = roughness + 1.0;
  float k = r*r / 8.0;
  return NV / (NV * (1.0 - k) + k);
}

float GeometrySmith(float NV, float NL, float roughness) {
    return GeometrySchlickGGX(NV, roughness) * GeometrySchlickGGX(NL, roughness);
}

vec3 CookTorranceBRDF(vec3 N, vec3 V, vec3 p, vec3 lightpos, vec3 lightcolor, float lightstrength, vec3 F0, vec3 albedo, float roughness, float metallic) {
  vec3 L = normalize(lightpos - p);
  vec3 H = normalize(V + L);
  float NL = max0(dot(N, L));
  float NV = max0(dot(N, V));
  float NH = max0(dot(N, H));
  float HV = clamp01(dot(H, V));
  float d = length(lightpos - p);
  vec3 radiance = lightstrength*lightcolor / (d*d);

  float NDF = DistributionGGX(NH, roughness);   
  float G = GeometrySmith(NV, NL, roughness);
  vec3 F = fresnelSchlick(HV, F0);
  vec3 diffuse = (vec3(1.0) - F)*(1.0 - metallic);
  vec3 specular = NDF * G * F / max(4.0 * NV * NL, 0.001);
	
  vec3 spec = (diffuse * albedo / PI + specular) * radiance * NL;
  return spec;
}



float sphIntersect(vec3 ro, vec3 rd, vec4 sph) {
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return -1.0;
    h = sqrt( h );
    return -b - h;
}

vec2 iSphere(vec3 ro, vec3 rd, vec3 pos, float r) {
    vec3 oc = ro - pos;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - r*r;
    float h = b*b - c;
    if(h<0.0) return vec2(-1.0,-1.0);
    h = sqrt( h );
    return vec2(-b - h, -b + h);
}

vec3 sphNormal(vec3 p, vec4 sph) {
  return normalize(p - sph.xyz);
}

float plaIntersect(vec3 ro, vec3 rd, vec4 p) {
    return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

// iq distance functions
//see here for example https://www.shadertoy.com/view/Xds3zN
float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }

float smin( in float a, in float b, in float s ) {
    float h = clamp( 0.5 + 0.5*(b-a)/s, 0.0, 1.0 );
    return mix(b, a, h) - h*(1.0-h)*s;
}

float sdPlane( vec3 p ) {
	return p.y;
}

float sdSphere( vec3 p, float s ) {
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b ) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdBoundingBox( vec3 p, vec3 b, float e ) {
    p = abs(p  )-b;
    vec3 q = abs(p+e)-e;    
    return min(min(length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0), length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)), length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float sdEllipsoid( in vec3 p, in vec3 r ) {
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float sdTorus( vec3 p, vec2 t ) {
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

float sdCappedTorus(in vec3 p, in vec2 sc, in float ra, in float rb) {
    p.x = abs(p.x);
    float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

float sdHexPrism( vec3 p, vec2 h ) {
    vec3 q = abs(p);
    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
    vec2 d = vec2(length(p.xy - vec2(clamp(p.x, -k.z*h.x, k.z*h.x), h.x))*sign(p.y - h.x), p.z-h.y);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdOctogonPrism( in vec3 p, in float r, float h ) {
  const vec3 k = vec3(-0.9238795325, 0.3826834323, 0.4142135623); 
  p = abs(p);
  p.xy -= 2.0*min(dot(vec2( k.x,k.y),p.xy),0.0)*vec2( k.x,k.y);
  p.xy -= 2.0*min(dot(vec2(-k.x,k.y),p.xy),0.0)*vec2(-k.x,k.y);
  p.xy -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
  vec2 d = vec2( length(p.xy)*sign(p.y), p.z-h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r ) {
	vec3 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

float sdRoundCone( in vec3 p, in float r1, float r2, float h ) {
    vec2 q = vec2( length(p.xz), p.y );
    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    float k = dot(q,vec2(-b,a));
    if(k < 0.0) return length(q) - r1;
    if(k > a*h) return length(q-vec2(0.0,h)) - r2;
    return dot(q, vec2(a,b) ) - r1;
}

float sdRoundCone(vec3 p, vec3 a, vec3 b, float r1, float r2) {
    vec3  ba = b - a;
    float l2 = dot(ba,ba);
    float rr = r1 - r2;
    float a2 = l2 - rr*rr;
    float il2 = 1.0/l2;
    vec3 pa = p - a;
    float y = dot(pa,ba);
    float z = y - l2;
    float x2 = dot2( pa*l2 - ba*y );
    float y2 = y*y*l2;
    float z2 = z*z*l2;
    float k = sign(rr)*rr*rr*x2;
    if(sign(z)*a2*z2 > k) return sqrt(x2 + z2)*il2 - r2;
    if(sign(y)*a2*y2 < k) return sqrt(x2 + y2)*il2 - r1;
    return (sqrt(x2*a2*il2)+y*rr)*il2 - r1;
}

float sdTriPrism( vec3 p, vec2 h ) {
    const float k = sqrt(3.0);
    h.x *= 0.5*k;
    p.xy /= h.x;
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x+k*p.y>0.0 ) p.xy=vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    float d1 = length(p.xy)*sign(-p.y)*h.x;
    float d2 = abs(p.z)-h.y;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float sdCylinder( vec3 p, vec2 h ) { // vertical
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}


float sdCylinder(vec3 p, vec3 a, vec3 b, float r) { // arbitrary orientation
    vec3 pa = p - a;
    vec3 ba = b - a;
    float baba = dot(ba,ba);
    float paba = dot(pa,ba);
    float x = length(pa*baba-ba*paba) - r*baba;
    float y = abs(paba-baba*0.5)-baba*0.5;
    float x2 = x*x;
    float y2 = y*y*baba;
    float d = (max(x,y)<0.0)?-min(x2,y2):(((x>0.0)?x2:0.0)+((y>0.0)?y2:0.0));
    return sign(d)*sqrt(abs(d))/baba;
}

float sdCone( in vec3 p, in vec2 c, float h ) {// vertical
    vec2 q = h*vec2(c.x,-c.y)/c.y;
    vec2 w = vec2( length(p.xz), p.y );
	vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
    vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
    float k = sign( q.y );
    float d = min(dot( a, a ),dot(b, b));
    float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
	return sqrt(d)*sign(s);
}
float sdCappedCone( in vec3 p, in float h, in float r1, in float r2 ) {
    vec2 q = vec2( length(p.xz), p.y );
    vec2 k1 = vec2(r2,h);
    vec2 k2 = vec2(r2-r1,2.0*h);
    vec2 ca = vec2(q.x-min(q.x,(q.y < 0.0)?r1:r2), abs(q.y)-h);
    vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot2(k2), 0.0, 1.0 );
    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
    return s*sqrt( min(dot2(ca),dot2(cb)) );
}


float sdCappedCone(vec3 p, vec3 a, vec3 b, float ra, float rb) {
    float rba  = rb-ra;
    float baba = dot(b-a,b-a);
    float papa = dot(p-a,p-a);
    float paba = dot(p-a,b-a)/baba;
    float x = sqrt( papa - paba*paba*baba );
    float cax = max(0.0,x-((paba<0.5)?ra:rb));
    float cay = abs(paba-0.5)-0.5;
    float k = rba*rba + baba;
    float f = clamp( (rba*(x-ra)+paba*baba)/k, 0.0, 1.0 );
    float cbx = x-ra - f*rba;
    float cby = paba - f;
    float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
    return s*sqrt(min(cax*cax + cay*cay*baba, cbx*cbx + cby*cby*baba));
}

float sdSolidAngle(vec3 pos, vec2 c, float ra) {
    vec2 p = vec2( length(pos.xz), pos.y );
    float l = length(p) - ra;
	float m = length(p - c*clamp(dot(p,c),0.0,ra) );
    return max(l,m*sign(c.y*p.x-c.x*p.y));
}

float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    float m = p.x + p.y + p.z - s;
    vec3 o = min(3.0*p - m, 0.0);
    o = max(6.0*p - m*2.0 - o*3.0 + (o.x+o.y+o.z), 0.0);
    return length(p - s*o/(o.x+o.y+o.z));
}

float sdPyramid( in vec3 p, in float h ) {
    float m2 = h*h + 0.25;
    p.xz = abs(p.xz);
    p.xz = (p.z>p.x) ? p.zx : p.xz;
    p.xz -= 0.5;
    vec3 q = vec3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);
    float s = max(-q.x,0.0);
    float t = clamp( (q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0 );
    float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
	float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);
    float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);
    return sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));;
}

float sdRhombus(vec3 p, float la, float lb, float h, float ra) {
    p = abs(p);
    vec2 b = vec2(la,lb);
    float f = clamp( (ndot(b,b-2.0*p.xz))/dot(b,b), -1.0, 1.0 );
	vec2 q = vec2(length(p.xz-0.5*b*vec2(1.0-f,1.0+f))*sign(p.x*b.y+p.z*b.x-b.x*b.y)-ra, p.y-h);
    return min(max(q.x,q.y),0.0) + length(max(q,0.0));
}


// http://iquilezles.org/www/articles/boxfunctions/boxfunctions.htm
vec2 iBox( in vec3 ro, in vec3 rd, in vec3 rad ) {
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
	return vec2( max( max( t1.x, t1.y ), t1.z ), min( min( t2.x, t2.y ), t2.z ) );
}


//BODY

float getHead(vec3 p) {
    vec3 brainDim = vec3(0.2, 0.23, 0.22);
    vec3 inBrain = p - vec3(0, 0.27, 0.0);
    float brain = sdEllipsoid(inBrain, brainDim);
    
    vec3 faceDim = vec3(0.04, 0.19, 0.03);
    faceDim.x += sin(p.y*5.0)*0.05;
    faceDim.z += cos(p.x*15.0)*0.02;
    faceDim.z += sin(p.y*6.0)*0.03;
    vec3 inFace = p - vec3(0, 0.18, 0.11);
    float face = sdBox(inFace, faceDim) - 0.1;
    
    float d = brain;
    d = smin(d, face, 0.1);
    return d;
}

float getUpperArm(vec3 p) {
    vec3 shoulderDim = vec3(0.23, 0.15, 0.18);
    float shoulder = sdEllipsoid(p - vec3(0.05, 0.05, 0.0), shoulderDim);
    
    float muscle1Rad = 0.09;
    muscle1Rad -= cos(p.x*8.0)*0.02;
    vec3 muscle1Pos1 = vec3(0.0, 0.05, 0.03);
    vec3 muscle1Pos2 = vec3(0.74, 0.05, 0.03);
    float muscle1 = sdCapsule(p, muscle1Pos1, muscle1Pos2, muscle1Rad);
    
    float muscle2Rad = 0.09;
    muscle2Rad += sin(p.x*7.0)*0.02;
    vec3 muscle2Pos1 = vec3(0.0, -0.04, -0.03);
    vec3 muscle2Pos2 = vec3(0.78, -0.02, -0.03);
    float muscle2 = sdCapsule(p, muscle2Pos1, muscle2Pos2, muscle2Rad);
    
    float d = shoulder;
    d = smin(d, muscle1, 0.03);
    d = smin(d, muscle2, 0.03);
    return d;
}

float getForearm(vec3 p) {
    const vec3 handPos = vec3(0.58, 0, 0);
    float rad = 0.06 + sin(p.x*9.0)*0.01;
    float muscle1 = sdCapsule(p, vec3(0.06, 0.06, 0.0), handPos+vec3(0, 0.05, 0), rad);
    float muscle2 = sdCapsule(p, vec3(0.04, -0.02, 0.03), handPos+vec3(0, -0.01, 0), rad);
    float elbow = length(p)-0.08;
    float d = muscle1;
    d = smin(d, muscle2, 0.03);
    d = smin(d, elbow, 0.05);
    return d;
}

float getHand(vec3 p) {
    vec3 handDim = vec3(0.08, 0.07, 0.01);
    float cu1 = cos(p.y*11.0-0.3);
	handDim.x += cu1*0.06;
    handDim.z += cu1*0.03;
    handDim.z -= sin(p.x*4.0)*0.05;
    float hand = sdBox(p - vec3(0.25, 0.02, 0.0), handDim) - 0.05;
    float thumb = sdCapsule(p, vec3(0.1, 0.02, 0.03), vec3(0.15, 0.18, 0.06), 0.04);
    float d = hand;
    d = smin(d, thumb, 0.07);
    return d;
}

float getUpperLeg(vec3 p) {
    const vec3 kneePos = vec3(0, -1.01, 0);
    float muscle1Rad = 0.15 - sin(p.y*4.0)*0.03;
    float muscle1 = sdCapsule(p, vec3(0.03, 0.0, 0.1), kneePos, muscle1Rad);
    float muscle2 = sdCapsule(p, vec3(-0.12, 0.0, -0.05), kneePos, muscle1Rad);
    float knee = sdEllipsoid(p - vec3(0, -0.95, 0.03), vec3(0.12, 0.2, 0.12));
    float d = muscle1;
    d = smin(d, muscle2, 0.02);
    d = smin(d, knee, 0.03);
    
    return d;
}

float getLowerLeg(vec3 p) {
    const vec3 footPos = vec3(0, -1.06, -0.08);
    float muscle1Rad = 0.1 - sin(p.y*4.0)*0.03;
    float muscle1 = sdCapsule(p, vec3(0.02, 0.0, 0.0), footPos, muscle1Rad);
    float muscle2Rad = 0.09 - sin(p.y*5.3)*0.05;
    float muscle2 = sdCapsule(p, vec3(-0.02, 0.04, -0.08), footPos + vec3(0.0, 0.04, -0.02), muscle2Rad);
    float d = muscle1;
    d = smin(d, muscle2, 0.02);
    return d;    
}

float getFoot(vec3 p) {
    vec3 footDim = vec3(0.04, 0.0, 0.19);
    footDim.x -= cos(p.z*13.0-0.4)*0.04;
    footDim.z += cos(p.x*14.0+0.2)*0.05;
    vec3 inFoot = p - vec3(0.03, -0.13, 0.19);
    float foot = sdBox(inFoot, footDim)-0.05;
    float ankle = sdEllipsoid(inFoot - vec3(0.0, 0.07, -0.13), vec3(0.1, 0.08, 0.18));
    float d = foot;
    d = smin(d, ankle, 0.1);
    return d;
}

float getTorso(vec3 p) {
    vec3 mainDim = vec3(0.35, 0.15, 0.05);
    mainDim.x -= cos(p.y*2.0+0.8)*0.19;
    mainDim.y -= cos(p.x*7.0)*0.05;
    vec3 inTorso = p - vec3(0, 0.15, 0.05);
    inTorso.z += s(-0.2, 0.5, inTorso.y)*0.2;
    float torso = sdBox(inTorso, mainDim) - 0.15;
    
    vec3 trapDim = vec3(0.15, 0.13, 0);
    vec3 inTrap = inTorso - vec3(0.2, 0.33, -0.07);
    inTrap.xy *= rot(0.4);
    inTrap.yz *= rot(-0.2);
    float trap = sdBox(inTrap, trapDim)-0.13;
    
    vec3 pecDim = vec3(0.11, 0.08, 0.0);
    pecDim.y += sin(inTorso.x*7.5)*0.05;
    vec3 inPec = inTorso - vec3(0.19, 0.2, 0.12);
    float pec = sdBox(inPec, pecDim) - 0.1;
    float pecMore = length(inPec)-0.15;
    pec = smin(pec, pecMore, 0.25);
    
    float spine = s(0.13, 0.0, p.x)*s(0.1, -0.3, p.z);
    
    float d = torso;
    d = smin(d, trap, 0.1);
    d = smin(d, pec, 0.05);
    d += spine*0.02;
    return d;
}

float getPelvis(vec3 p) {
    vec3 mainDim = vec3(0.17, 0.3, 0);
    mainDim.x += sin(p.y*6.0)*0.04;
    vec3 inMain = p - vec3(0, -0.45, 0.07);
    inMain.z -= cos(inMain.y*6.0)*0.02;
    
    float main = sdBox(inMain, mainDim) - 0.2;
    
    vec3 absDim = vec3(0.13, 0.29, 0.0);
    absDim.z -= cos(p.x*30.0)*0.007;
    absDim.z -= cos(p.y*36.0)*0.007;
    vec3 inAbs = inMain - vec3(0, 0.1, 0.13);
    float absD = sdBox(inAbs, absDim)-0.1;
    
    vec3 penisDim = vec3(0.03, 0.05, 0.05);
    penisDim.x -= sin(p.y*10.0)*0.03;
    vec3 inPenis = p - vec3(0, -0.9, 0.13);
    inPenis.z += inPenis.y*0.2;
    float penis = sdBox(inPenis, penisDim)-0.12;
    
    float butt = sdEllipsoid(p - vec3(0.17, -0.75, -0.03),
                             vec3(0.2, 0.28, 0.2));
    
    float spine = s(0.1, 0.0, p.x)*s(0.1, -0.1, p.z);
    
    float d = main;
    d = smin(d, absD, 0.1);
    d = smin(d, penis, 0.1);
    d = smin(d, butt, 0.1);
    d += spine*0.02;
    return d;
}

float getNeck(vec3 p) {
    return sdCapsule(p, vec3(0.0), vec3(0, 0.24, 0.07), 0.15);
}

