#version 300 es
//settings precision is required (sometimes...)
precision mediump float; //max float is 2^14=16384
//precision mediump sampler2D;
//precision highp float; //max float is 2^62
//precision mediump sampler3D; //setting (any) precision is required for some reason
//precision highp sampler3D;

float clamp01(float x) {return clamp(x, 0.0, 1.0);}
vec2 clamp01(vec2 x) {return clamp(x, 0.0, 1.0);}
vec3 clamp01(vec3 x) {return clamp(x, 0.0, 1.0);}

float max0(float x ) {
    return max(0.0, x);
}

float invmix(float a, float b, float t) {
	return clamp01((t-a)/(b-a));
}

const float PI = 4.0*atan(1.0); //3.14159265359;

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

vec3 sphNormal(vec3 p, vec4 sph) {
  return normalize(p - sph.xyz);
}

float plaIntersect(vec3 ro, vec3 rd, vec4 p) {
    return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

// iq distance functions
float sdBox( in vec3 p, in vec3 b ) {
	vec3 d = abs(p) - b;
	return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float sdCapsule( in vec3 p, in vec3 a, in vec3 b, in float r ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}
float sdEllipsoid( in vec3 p, in vec3 r ) {
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}
float smin( in float a, in float b, in float s ) {
    float h = clamp( 0.5 + 0.5*(b-a)/s, 0.0, 1.0 );
    return mix(b, a, h) - h*(1.0-h)*s;
}