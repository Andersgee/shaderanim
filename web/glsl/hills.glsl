#ifdef VERT

in vec2 clipspace;

out vec2 ssc;

void main() {
  ssc = clipspace;
  gl_Position = vec4(ssc, 0.0, 1.0);
}

#endif


///////////////////////////////////////////////////////////////////////////////

#ifdef FRAG

in vec2 ssc;
uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;


#define MOD2 vec2(3.07965, 7.4235)
vec3 sunLight  = normalize( vec3(  0.35, 0.2,  0.3 ) );
vec3 cameraposition;
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

float FractalNoise(in vec2 xy) {
	float w = .7;
	float f = 0.0;

	for (int i = 0; i < 3; i++) {
		f += Noise(xy) * w;
		w = w*0.6;
		xy = 2.0 * xy;
	}
	return f;
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
	return clamp01(sky);
}

float CircleOfConfusion(float t) {
	return max(t * .04, (2.0 / iResolution.y) * (1.0+t));
}

float Linstep(float a, float b, float t) {
	return clamp01((t-a)/(b-a));
}

vec2 Voronoi( in vec2 x ) {
	vec2 p = floor( x );
	vec2 f = fract( x );
	float res=100.0,id;
	for( int j=-1; j<=1; j++ )
	for( int i=-1; i<=1; i++ ) {
		vec2 b = vec2( float(i), float(j) );
		vec2 r = vec2( b ) - f  + Hash( p + b );
		float d = dot(r,r);
		if( d < res ) {
			res = d;
			id  = Hash(p+b);
		}			
    }
	return vec2(max(.4-sqrt(res), 0.0),id);
}

vec3 DE(vec3 p) {
	float base = Terrain(p.xz).x - 1.9;
	float height = Noise(p.xz*2.0)*.75 + Noise(p.xz)*.35 + Noise(p.xz*.5)*.2;
	//p.y += height;
	float y = p.y - base-height;
	y = y*y;
	vec2 ret = Voronoi((p.xz*2.5+sin(y*4.0+p.zx*12.3)*.12+vec2(sin(iTime*2.3+1.5*p.z),sin(iTime*3.6+1.5*p.x))*y*.5));
	float f = ret.x * .6 + y * .58;
	return vec3( y - f*1.4, clamp01(f * 1.5), ret.y);
}

vec3 GrassBlades(in vec3 rO, in vec3 rD, in vec3 mat, in float dist) {
	float d = 0.0;
	// Only calcameraXdirlate cCoC once is enough here...
	float rCoC = CircleOfConfusion(dist*.3);
	float alpha = 0.0;
	
	vec4 col = vec4(mat*0.15, 0.0);

	for (int i = 0; i < 15; i++) {
		if (col.w > .99) break;
		vec3 p = rO + rD * d;
		
		vec3 ret = DE(p);
		ret.x += .5 * rCoC;

		if (ret.x < rCoC) {
			alpha = (1.0 - col.y) * Linstep(-rCoC, rCoC, -ret.x);//calcameraXdirlate the mix like cloud density
			// Mix material with white tips for grass...
			vec3 gra = mix(mat, vec3(.35, .35, min(pow(ret.z, 4.0)*35.0, .35)), pow(ret.y, 9.0)*.7) * ret.y;
			col += vec4(gra * alpha, alpha);
		}
		d += max(ret.x * .7, .1);
	}
	if(col.w < .2)
		col.xyz = vec3(0.1, .15, 0.05);
	return col.xyz;
}

void DoLighting(inout vec3 mat, in vec3 pos, in vec3 normal, in vec3 eyeraydir, in float dis) {
	float h = dot(sunLight,normal);
	mat = mat * sunColour*(max(h, 0.0)+.2);
}

vec3 ApplyFog( in vec3  rgb, in float dis, in vec3 rd) {
	float fogAmount = clamp01(dis*dis* 0.0000012);
	return mix( rgb, GetSky(rd), fogAmount );
}

vec3 TerrainColour(vec3 pos, vec3 rd,  vec3 normal, float dis, float type) {
	vec3 mat;
	if (type == 0.0) {
		mat = mix(vec3(.0,.3,.0), vec3(.2,.3,.0), Noise(pos.xz*.025)); // Random colour
		float t = FractalNoise(pos.xz * .1)+.5; // Random shadows
		mat = GrassBlades(pos, rd, mat, dis) * t; // Do grass blade tracing
		DoLighting(mat, pos, normal,rd, dis);
	}
	mat = ApplyFog(mat, dis, rd);
	return mat;
}

vec3 PostEffects(vec3 rgb, vec2 xy) {
	// Gamma first...
	rgb = pow(rgb, vec3(0.45));
	
	// Then...
	#define CONTRAST 1.1
	#define SATURATION 1.3
	#define BRIGHTNESS 1.3
	rgb = mix(vec3(.5), mix(vec3(dot(vec3(.2125, .7154, .0721), rgb*BRIGHTNESS)), rgb*BRIGHTNESS, SATURATION), CONTRAST);
	// Vignette...
	rgb *= .4+0.5*pow(40.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.2 );	
	return rgb;
}

void main(void) {
    vec2 iMouse = vec2(0.0, 0.0);

	float m = (iMouse.x/iResolution.x)*300.0;
	float gTime = (iTime*5.0+m+2352.0)*.006;
    vec2 xy = gl_FragCoord.xy / iResolution.xy;
	vec2 uv = (-1.0 + 2.0 * xy) * vec2(iResolution.x/iResolution.y,1.0);
	vec3 cameratarget;

    
	cameraposition = CameraPath(gTime + 0.0);
    cameraposition.x -= 3.0;
	cameratarget = CameraPath(gTime + .009);
	cameraposition.y += Terrain(CameraPath(gTime + .009).xz).x;
	cameratarget.y = cameraposition.y;
	
	vec3 cameradir = normalize(cameratarget-cameraposition);
	vec3 updir = vec3(0.0, 1.0, 0.0);
	vec3 cameraXdir = cross(cameradir, updir);
	vec3 cameraYdir = cross(cameraXdir, cameradir);

	vec3 rd = normalize(uv.x*cameraXdir + uv.y*cameraYdir + 1.3*cameradir);

	vec3 col;
	float distance;
	float type;

    if( !Scene(cameraposition, rd, distance, type) ) {
		col = GetSky(rd); // Missed scene, now just get the sky
	} else {
		vec3 pos = cameraposition + distance * rd; // Get world coordinate of landscape
		// Get normal from sampling the high definition height map
		// Use the distance to sample larger gaps to help stop aliasing
		vec2 p = vec2(0.1, 0.0);
		vec3 nor = vec3(0.0, Terrain(pos.xz).x, 0.0);
		vec3 v2 = nor-vec3(p.x,	Terrain(pos.xz+p).x, 0.0);
		vec3 v3	= nor-vec3(0.0,	Terrain(pos.xz-p.yx).x, -p.x);
		nor = cross(v2, v3);
		nor = normalize(nor);

		// Get the colour using all available data
		col = TerrainColour(pos, rd, nor, distance, type);
	}

    // bri is the brightness of sun at the centre of the camera raydirection.
	// Yeah, the lens flares is not exactly subtle, but it was good fun making it.
	float bri = dot(cameradir, sunLight)*.75;
    if (bri > 0.0) {
		vec2 sunPos = vec2( dot( sunLight, cameraXdir ), dot( sunLight, cameraYdir ) );
		vec2 uvT = uv-sunPos;
		uvT = uvT*(length(uvT));
		bri = pow(bri, 6.0)*.8;

		// glare = the red shifted blob...
		float glare1 = max(dot(normalize(vec3(rd.x, rd.y+.3, rd.z)),sunLight),0.0)*1.4;
		// glare2 is the yellow ring...
		float glare2 = max(1.0-length(uvT+sunPos*.5)*4.0, 0.0);
		uvT = mix (uvT, uv, -2.3);
		// glare3 is a purple splodge...
		float glare3 = max(1.0-length(uvT+sunPos*5.0)*1.2, 0.0);

		col += bri * vec3(1.0, .0, .0)  * pow(glare1, 12.5)*.05;
		col += bri * vec3(1.0, 1.0, 0.2) * pow(glare2, 2.0)*2.5;
		col += bri * sunColour * pow(glare3, 2.0)*3.0;
	}
    col = PostEffects(col, xy);	
	fragColor=vec4(col, 1.0);
}


#endif