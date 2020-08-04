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

vec2 spherenormal2uv(vec3 N, float rotspeed) {
  float u = atan(N.z, N.x)/PI + 0.5;
  float v = 0.5*N.y + 0.5;
  //return vec2(u,v);
  u = fract(u - time*rotspeed);
  return vec2(u,1.0-v);
}

void main(void) {
  float aspect = 16.0/9.0;

  vec3 rd = normalize(vec3(ssc.x*aspect, ssc.y, 3.5));
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

  float daylight = 1.0;
  vec3 col_earthnight = vec3(0.0);
  float roughness = 0.75;
  float lightstrength = 1000.0;
  vec3 albedo = vec3(0.5, 0.4, 0.4);

  if (st>0.0) {
    p = ro+rd*st;
    N = sphNormal(p,sph);
    t = st;

    vec3 L = normalize(lightpos - p);
    daylight = max0(dot(N,L));
    vec2 sphereuv = spherenormal2uv(N, 0.04);
    vec2 sphereuvfast = spherenormal2uv(N, 0.05);

    vec3 col_earthday = srgb2rgb(texture(earthday, sphereuv).xyz);
    col_earthnight = srgb2rgb(texture(earthnight, sphereuv).xyz);
    vec3 col_earthclouds = srgb2rgb(texture(earthclouds, sphereuvfast).xyz);
    float cloudtransparency = texture(earthcloudtrans, sphereuvfast).x;
    float cloudopacity = 1.0 - cloudtransparency;
    float iswater = texture(earthwater, sphereuv).x;
    float bump = texture(earthbump, sphereuv).x;

    roughness = 1.0-iswater*0.5;
    //metallic = 1.0-iswater;
    col_earthnight = mix(col_earthnight, col_earthclouds, cloudtransparency*(daylight*0.25));
    albedo = mix(col_earthclouds, col_earthday, clamp01(cloudtransparency*1.75));
  }
  
  
  float ao = 0.1;
  vec3 F0 = mix(vec3(0.02), albedo, metallic);

  vec3 Lo = vec3(0.0);
  for(int i = 0; i < 1; ++i)  {
    Lo += CookTorranceBRDF(N, V, p, lightpos, lightcolor, lightstrength, F0, albedo, roughness, metallic);
  }

  vec3 ambient = vec3(0.03) * albedo * ao;
  vec3 color = ambient + mix(col_earthnight, Lo, daylight);

  color = tonemap(color, 1.0);
  vec3 col = t>0.0 ? vec3(rgb2srgb(color)) : ambient;
  fragcolor = vec4(col,1.0);
}

#endif
