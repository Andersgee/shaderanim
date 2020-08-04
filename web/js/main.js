async function fetchglsl() {
  return await Promise.all([
    fetch("../glsl/common.glsl").then((res) => res.text()),
    fetch("../glsl/basic.glsl").then((res) => res.text()),
  ]);
}

function setup() {
  fetchglsl().then((glsl) => main(glsl));
}

function shaderlayout() {
  let layout = {};
  layout.attributes = {
    clipspace: 2,
  };

  layout.uniforms = {
    t: "uniform1f",
    earthday: "uniform1i",
    earthnight: "uniform1i",
  };

  let uniforms = {
    t: 1.0,
    earthday: 0,
    earthnight: 1,
  };

  texturefilenames = ["../textures/earthday.jpg", "../textures/earthnight.jpg"];

  return [layout, uniforms, texturefilenames];
}

function main(glsl) {
  let canvas = document.getElementById("canvas");
  let gl = webgl(canvas);
  let [layout, uniforms, texturefilenames] = shaderlayout();
  let basicshader = createprogram(gl, layout, glsl[0], glsl[1]);
  gl.useProgram(basicshader);
  bindclipspacequad(gl, basicshader);
  bindtextures(gl, texturefilenames);

  let animstart = performance.now();
  let animframe = requestAnimationFrame(animate);
  function animate(timestamp) {
    uniforms.t = (timestamp - animstart) / 1000;
    draw(gl, basicshader, uniforms);
    animframe = requestAnimationFrame(animate);
  }
}

window.onload = setup();
