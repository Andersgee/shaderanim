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
vec3 campos;
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

float Noise(in vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
	float a = mix( Hash(n+0.0), Hash(n+1.0), f.x);
    float b = mix( Hash(n+57.0), Hash(n+58.0), f.x);
	float res = mix(a, b, f.y);
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

vec2 groundheight( in vec2 p) {
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

vec3 groundnormal(vec3 pos) {
	vec2 p = vec2(0.1, 0.0);
	vec3 v1 = vec3(0.0, groundheight(pos.xz).x, 0.0);
	vec3 v2 = v1 - vec3(p.x, groundheight(pos.xz+p).x, 0.0);
	vec3 v3	= v1 - vec3(0.0, groundheight(pos.xz-p.yx).x, -p.x);
	vec3 N = normalize(cross(v2, v3));
	return N;
}

vec2 Map(in vec3 p) {
	vec2 h = groundheight(p.xz);
    return vec2(p.y - h.x, h.y);
}

float BinarySubdivision(in vec3 ro, in vec3 rd, float t, float oldT) {
	float halfwayT = 0.0;
	for (int n = 0; n < 5; n++) {
		halfwayT = 0.5*(oldT + t );
		if (Map(ro + halfwayT*rd).x < .05) {
			t = halfwayT;
		} else {
			oldT = halfwayT;
		}
	}
	return t;
}

bool Scene(in vec3 ro, in vec3 rd, out float dist, out float type ) {
    float t = 5.0;
	float oldT = 0.0;
	float delta = 0.;
	vec2 h = vec2(1.0, 1.0);
	bool hit = false;
	for( int j=0; j < 70; j++ ) {
	    vec3 p = ro + t*rd;
		h = Map(p);
		if(h.x < 0.05) {
			hit = true;
			break;
		}
		delta = h.x + (t*0.03);
		oldT = t;
		t += delta;
	}
    type = h.y;
    dist = BinarySubdivision(ro, rd, t, oldT);
	return hit;
}

vec3 skycolor(in vec3 rd) {
	float sunAmount = max( dot( rd, sunLight), 0.0 );
	float v = pow(1.0-max(rd.y,0.0),6.);
	vec3  sky = mix(vec3(.1, .2, .3), vec3(.32, .32, .32), v);
	sky = sky + sunColour * sunAmount * sunAmount * .25;
	sky = sky + sunColour * min(pow(sunAmount, 800.0)*1.5, .3);
	return clamp01(sky);
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
	float base = groundheight(p.xz).x - 1.9;
	float height = Noise(p.xz*2.0)*.75 + Noise(p.xz)*.35 + Noise(p.xz*.5)*.2;
	float y = p.y - base-height;
	y = y*y;
	vec2 xz = (p.xz*2.5+sin(y*4.0+p.zx*12.3)*.12+vec2(sin(iTime*2.3+1.5*p.z),sin(iTime*3.6+1.5*p.x))*y*.5);
	vec2 ret = Voronoi(xz);
	float f = ret.x * .6 + y * .58;
	return vec3( y - f*1.4, clamp01(f * 1.5), ret.y);
}

float CircleOfConfusion(float t) {
	return max(t * .04, (2.0 / iResolution.y) * (1.0+t));
}

vec3 GrassBlades(in vec3 ro, in vec3 rd, in vec3 mat, in float dist) {
	float d = 0.0;
	float rCoC = CircleOfConfusion(dist*.3); // Only calculate cCoC once is enough here
	float alpha = 0.0;	
	vec4 col = vec4(mat*0.15, 0.0);
	for (int i = 0; i < 15; i++) {
		if (col.w > .99) break;
		vec3 p = ro + rd * d;
		vec3 ret = DE(p);
		ret.x += .5 * rCoC;
		if (ret.x < rCoC) {
			alpha = (1.0 - col.y) * invmix(-rCoC, rCoC, -ret.x);//calculate the mix like cloud density
			vec3 gra = mix(mat, vec3(.35, .35, min(pow(ret.z, 4.0)*35.0, .35)), pow(ret.y, 9.0)*.7) * ret.y; // Mix material with white tips for grass
			col += vec4(gra * alpha, alpha);
		}
		d += max(ret.x * .7, .1);
	}
	if(col.w < .2){
		col.xyz = vec3(0.1, .15, 0.05);
	}
	return col.xyz;
}

vec3 groundcolor(vec3 pos, vec3 rd, vec3 N, float dis, float type) {
	vec3 mat;
	mat = mix(vec3(0.0, 0.3, 0.0), vec3(0.2, 0.3, 0.0), Noise(pos.xz*.025)); // Random colour
	float t = FractalNoise(pos.xz * .1)+.5; // Random shadows
	mat = GrassBlades(pos, rd, mat, dis) * t; // Do grass blade tracing
	float h = dot(sunLight,N);
	mat *= sunColour*(max(h, 0.0)+0.2);
	float fogAmount = clamp01(dis*dis* 0.0000012);
	mat = mix(mat, skycolor(rd), fogAmount);
	return mat;
}

vec3 postprocess(vec3 rgb, vec2 xy) {
	vec3 srgb = rgb2srgb(rgb);
	float CONTRAST = 1.1;
	float SATURATION = 1.3;
	float BRIGHTNESS = 1.3;
	srgb = mix(vec3(0.5), mix(vec3(dot(vec3(.2125, .7154, .0721), srgb*BRIGHTNESS)), srgb*BRIGHTNESS, SATURATION), CONTRAST);
	srgb *= 0.4 + 0.5*pow(40.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.2 ); // Vignette
	return srgb;
}

void main(void) {
    vec2 iMouse = vec2(0.0, 0.0);

	float m = (iMouse.x/iResolution.x)*300.0;
	float gTime = (iTime*5.0+m+2352.0)*.006;
    vec2 xy = gl_FragCoord.xy / iResolution.xy;
	vec2 uv = (-1.0 + 2.0 * xy) * vec2(iResolution.x/iResolution.y,1.0);
	vec3 camtarget;

	campos = CameraPath(gTime + 0.0);
	camtarget = CameraPath(gTime + .009);

	campos.x -= 3.0;
	campos.y += groundheight(camtarget.xz).x;
	camtarget.y = campos.y;
	
	vec3 camdir = normalize(camtarget-campos);
	vec3 updir = vec3(0.0, 1.0, 0.0);
	vec3 camXdir = cross(camdir, updir);
	vec3 camYdir = cross(camXdir, camdir);

	vec3 rd = normalize(uv.x*camXdir + uv.y*camYdir + 1.3*camdir);

	vec3 col;
	float dist;
	float type;

    if( !Scene(campos, rd, dist, type) ) {
		col = skycolor(rd);
	} else {
		vec3 pos = campos + dist*rd;
		vec3 N = groundnormal(pos);
		col = groundcolor(pos, rd, N, dist, type);
	}

    // bri is the brightness of sun at the centre of the camera raydirection.
	float bri = dot(camdir, sunLight)*.75;
    if (bri > 0.0) {
		vec2 sunPos = vec2(dot(sunLight, camXdir), dot(sunLight, camYdir));
		vec2 uvT = uv-sunPos;
		uvT = uvT*length(uvT);
		bri = 0.8*pow(bri, 6.0);

		float glare1 = max(dot(normalize(vec3(rd.x, rd.y+.3, rd.z)),sunLight),0.0)*1.4; //red shifted blob
		float glare2 = max(1.0-length(uvT+sunPos*.5)*4.0, 0.0); //yellow ring
		uvT = mix(uvT, uv, -2.3);
		float glare3 = max(1.0-length(uvT+sunPos*5.0)*1.2, 0.0); //purple splodge

		col += bri * vec3(1.0, .0, .0) * pow(glare1, 12.5)*.05;
		col += bri * vec3(1.0, 1.0, 0.2) * pow(glare2, 2.0)*2.5;
		col += bri * sunColour * pow(glare3, 2.0)*3.0;
	}
    col = postprocess(col, xy);	
	fragColor=vec4(col, 1.0);
}


#endif