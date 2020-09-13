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

vec3 cameraPos;

#define MOD2 vec2(3.07965, 7.4235)

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
	
    /*
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
	*/

	fragColor=vec4(1.0, 0.0, 0.0, 1.0);
}


#endif