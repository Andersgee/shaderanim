#ifdef VERT

in vec2 clipspace;

out vec2 uv;
out vec2 ssc;

void main() {
  ssc = clipspace;
  uv = 0.5 + 0.5*ssc;
  gl_Position = vec4(ssc, 0.0, 1.0);
}

#endif


///////////////////////////////////////////////////////////////////////////////

#ifdef FRAG

in vec2 uv;
in vec2 ssc;
uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;


#define MOD2 vec2(3.07965, 7.4235)
vec3 sunLight  = normalize( vec3(  0.35, 0.2,  0.3 ) );
vec3 cameraPos;
vec3 sunColour = vec3(1.0, .75, .6);
const mat2 rotate2D = mat2(1.932, 1.623, -1.623, 1.952);
float gTime = 0.0;

vec3 CameraPath( float t ) {
	//t = time + t;
    vec2 p = vec2(200.0 * sin(3.54*t), 200.0 * cos(2.0*t) );
	return vec3(p.x+55.0,  12.0+sin(t*.3)*6.5, -94.0+p.y);
}

float Hash( float p ) {
	vec2 p2 = fract(vec2(p) / MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y);
}

float Hash(vec2 p) {
	p  = fract(p / MOD2);
    p += dot(p.xy, p.yx+19.19);
    return fract(p.x * p.y);
}

float Noise( in vec2 x ) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
    float res = mix(mix( Hash(n+  0.0), Hash(n+  1.0),f.x), mix( Hash(n+ 57.0), Hash(n+ 58.0),f.x),f.y);
    return res;
}

vec2 Terrain( in vec2 p) {
	float type = 0.0;
	vec2 pos = p*0.003;
	float w = 50.0;
	float f = .0;
	for (int i = 0; i < 3; i++) {
		f += Noise(pos) * w;
		w = w * 0.62;
		pos *= 2.5;
	}

	return vec2(f, type);
}

vec2 Map(in vec3 p) {
	vec2 h = Terrain(p.xz);
    return vec2(p.y - h.x, h.y);
}

float BinarySubdivision(in vec3 rO, in vec3 rD, float t, float oldT) {
	float halfwayT = 0.0;
	for (int n = 0; n < 5; n++) {
		halfwayT = (oldT + t ) * .5;
		if (Map(rO + halfwayT*rD).x < .05) {
			t = halfwayT;
		} else {
			oldT = halfwayT;
		}
	}
	return t;
}

bool Scene(in vec3 rO, in vec3 rD, out float resT, out float type ) {
    float t = 5.;
	float oldT = 0.0;
	float delta = 0.;
	vec2 h = vec2(1.0, 1.0);
	bool hit = false;
	for( int j=0; j < 70; j++ ) {
	    vec3 p = rO + t*rD;
		h = Map(p); // ...Get this position's height mapping.

		// Are we inside, and close enough to fudge a hit?...
		if( h.x < 0.05) {
			hit = true;
            break;
		}
	        
		delta = h.x + (t*0.03);
		oldT = t;
		t += delta;
	}
    type = h.y;
    resT = BinarySubdivision(rO, rD, t, oldT);
	return hit;
}

vec3 GetSky(in vec3 rd) {
	float sunAmount = max( dot( rd, sunLight), 0.0 );
	float v = pow(1.0-max(rd.y,0.0),6.);
	vec3  sky = mix(vec3(.1, .2, .3), vec3(.32, .32, .32), v);
	sky = sky + sunColour * sunAmount * sunAmount * .25;
	sky = sky + sunColour * min(pow(sunAmount, 800.0)*1.5, .3);
	return clamp(sky, 0.0, 1.0);
}

void main(void) {
    vec2 iMouse = vec2(0.5, 0.5);

	float m = (iMouse.x/iResolution.x)*300.0;
	float gTime = (iTime*5.0+m+2352.0)*.006;
    vec2 xy = gl_FragCoord.xy / iResolution.xy;
	//vec2 uv = (-1.0 + 2.0 * xy) * vec2(iResolution.x/iResolution.y,1.0);
	vec3 camTar;

    
	cameraPos = CameraPath(gTime + 0.0);
    cameraPos.x -= 3.0;
	camTar	 = CameraPath(gTime + .009);
	cameraPos.y += Terrain(CameraPath(gTime + .009).xz).x;
	camTar.y = cameraPos.y;
	
    
	float roll = .4*sin(gTime+.5);
	vec3 cw = normalize(camTar-cameraPos);
	vec3 cp = vec3(sin(roll), cos(roll),0.0);
	vec3 cu = cross(cw,cp);
	vec3 cv = cross(cu,cw);
	vec3 dir = normalize(uv.x*cu + uv.y*cv + 1.3*cw);
	mat3 camMat = mat3(cu, cv, cw);

	vec3 col;
	float distance;
	float type;

    if( !Scene(cameraPos, dir, distance, type) ) {
		col = GetSky(dir); // Missed scene, now just get the sky
	}

	fragColor=vec4(1.0, 0.0, 0.0, 1.0);
}


#endif