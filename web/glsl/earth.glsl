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

uniform sampler2D earthday;
uniform sampler2D earthnight;
uniform sampler2D earthclouds;
uniform sampler2D earthcloudtrans;
uniform sampler2D earthwater;
uniform sampler2D earthbump;

uniform float time;

out vec4 fragcolor;

float sphIntersect(vec3 ro, vec3 rd, vec4 sph) {
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return -1.0;
    h = sqrt( h );
    return -b - h;
}

vec3 sphNormal(vec3 p, vec4 sph) {
  return normalize(p - sph.xyz);
}

float plaIntersect(vec3 ro, vec3 rd, vec4 p) {
    return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

vec2 spherenormal2uv(vec3 N, float rotspeed) {
  float u = atan(N.z, N.x)/PI + 0.5;
  float v = 0.5*N.y + 0.5;
  //return vec2(u,v);
  u = fract(u - time*rotspeed);
  return vec2(u,1.0-v);
}

void main(void) {
  float aspect = 16.0/9.0;

  vec3 rd = normalize(vec3(ssc.x*aspect, ssc.y, 3.0));
  vec3 ro = vec3(0.0,0.5,-3.4);
  vec3 V = -rd;
  vec3 N = vec3(0.0, 1.0, 0.0);

  float t = plaIntersect(ro, rd, vec4(N, 1.0));
  vec3 p = ro+rd*t;
  vec3 lightcolor = vec3(1.0, 0.94, 0.87);
      
  vec3 lightpos = vec3(7.0, 3.0, -1.0);

  vec4 sph = vec4(0.0, 0.0, 0.0, 1.0);
  float st = sphIntersect(ro, rd, sph);

  float metallic = 0.1;

  if (st>0.0) {
    p = ro+rd*st;
    N = sphNormal(p,sph);
    t = st;

    float rotspeed = 0.1;
    float time = 0.0;
    vec2 sphereuv = spherenormal2uv(N, 0.04);
    vec2 sphereuvfast = spherenormal2uv(N, 0.05);

    vec3 col_earthday = srgb2rgb(texture(earthday, sphereuv).xyz);
    vec3 col_earthnight = srgb2rgb(texture(earthnight, sphereuv).xyz);
    vec3 col_earthclouds = srgb2rgb(texture(earthclouds, sphereuvfast).xyz);
    float cloudtransparency = 1.75*texture(earthcloudtrans, sphereuvfast).x;
    float iswater = texture(earthwater, sphereuv).x;
    float bump = texture(earthbump, sphereuv).x;

    vec3 mixedcol = mix(col_earthnight, col_earthday, 0.999);
    lightcolor = mix(col_earthclouds, mixedcol, clamp01(cloudtransparency));
  }

  float lightstrength = 1000.0;
  vec3 albedo = vec3(0.5);
  float roughness = 0.75;//lightcolor.b > 0.3 ? 0.2 : 0.5;
  float ao = 0.1;
  vec3 F0 = mix(vec3(0.02), albedo, metallic);

  vec3 Lo = vec3(0.0);
  for(int i = 0; i < 1; ++i)  {
  Lo += CookTorranceBRDF(N, V, p, lightpos, lightcolor, lightstrength, F0, albedo, roughness, metallic);
  }

  vec3 ambient = vec3(0.03) * albedo * ao;
  vec3 color = ambient + Lo;

  color = tonemap(color, 1.0);

  vec3 col = t>0.0 ? vec3(rgb2srgb(color)) : ambient;
  fragcolor = vec4(col,1.0);

}

/*
void main(void) {
    float aspect = 16.0/9.0
    
    vec3 rd = normalize(vec3(ssc.x*aspect, ssc.y, 10.0));
    vec3 ro = vec3(0.0,0.5,-3.4);
    vec3 V = -rd;
    vec3 N = vec3(0.0, 1.0, 0.0);
    
    float t = plaIntersect(ro, rd, vec4(N, 1.0));
    vec3 p = ro+rd*t;
    vec3 lightcolor = vec3(1.0, 0.94, 0.87);
        
    vec3 lightpos = vec3(7.0, 3.0, -1.0);
    
    vec4 sph = vec4(0.0, 0.0, 0.0, 1.0);
    float st = sphIntersect(ro, rd, sph);
    
    float metallic = 0.1;
    
    if (st>0.0) {
        p = ro+rd*st;
    	N = sphNormal(p,sph);
        t = st;
        
        float rotspeed = 0.1;
        float time = 0.0;
        vec2 sphereuv = spherenormal2uv(N);
        vec3 c_earthday = srgb2rgb(texture(earthday, sphereuv).xyz);
        //vec3 earthnight = srgb2rgb(texture(iChannel1, sphereuv).xyz);
		//vec3 earthclouds = srgb2rgb(texture(iChannel2, sphereuv).xyz);
        
        lightcolor = mix(lightcolor, c_earthday, 0.995);
    }
  
  	float lightstrength = 1000.0;
 	vec3 albedo = vec3(0.5);
	float roughness = 0.75;//lightcolor.b > 0.3 ? 0.2 : 0.5;
	float ao = 0.1;
 	vec3 F0 = mix(vec3(0.02), albedo, metallic);
    
    vec3 Lo = vec3(0.0);
  	for(int i = 0; i < 1; ++i)  {
        Lo += CookTorranceBRDF(N, V, p, lightpos, lightcolor, lightstrength, F0, albedo, roughness, metallic);
    }
        
    vec3 ambient = vec3(0.03) * albedo * ao;
  	vec3 color = ambient + Lo;
    
    color = tonemap(color, 1.0);
    
    vec3 col = t>0.0 ? vec3(rgb2srgb(color)) : ambient;
	fragcolor = vec4(col,1.0);
}
*/
#endif
