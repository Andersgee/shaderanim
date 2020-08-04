#ifdef VERT

in vec2 clipspace;

out vec2 uv;

void main() {
  uv = 0.5 + 0.5*clipspace.xy;
  gl_Position = vec4(clipspace, 0.0, 1.0);
}

#endif

///////////////////////////////////////////////////////////////////////////////

#ifdef FRAG

in vec2 uv;

uniform sampler2D earthday;
uniform sampler2D earthnight;
uniform float t;


out vec4 fragcolor;

void main(void) {
  //vec3 color = vec3(1.0, 0.0, 0.0);
  //fragcolor = vec4(color/t, 1.0);

  vec3 color1 = texture(earthday, uv).xyz;
  vec3 color2 = texture(earthnight, uv).xyz;
  vec3 color = mix(color1, color2, 0.5);
  fragcolor = vec4(color, 1.0);
}

#endif