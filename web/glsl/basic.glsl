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

uniform float t;
uniform sampler2D earthday;

out vec4 fragcolor;

void main(void) {
  //vec3 color = vec3(1.0, 0.0, 0.0);
  //fragcolor = vec4(color/t, 1.0);

  vec3 color = texture(earthday, uv).xyz;
  fragcolor = vec4(color, 1.0);
}

#endif