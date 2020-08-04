#ifdef VERT

in vec2 clipspace;

uniform float t;

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

out vec4 fragcolor;

void main(void) {
  vec3 color = vec3(1.0, 0.0, 0.0);
  fragcolor = vec4(color/t, 1.0);
}

#endif