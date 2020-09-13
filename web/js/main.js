async function fetchglsl() {
  return await Promise.all([
    fetch("../glsl/common.glsl").then((res) => res.text()),
    //fetch("../glsl/earth.glsl").then((res) => res.text()),
    fetch("../glsl/hills.glsl").then((res) => res.text()),
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
    iTime: "uniform1f",
    iResolution: "uniform2fv",
    earthday: "uniform1i",
    earthnight: "uniform1i",
    earthclouds: "uniform1i",
    earthcloudtrans: "uniform1i",
    earthwater: "uniform1i",
    earthbump: "uniform1i",
  };

  let uniforms = {
    iTime: 0.0,
    iResolution: [1280, 720],
    earthday: 0,
    earthnight: 1,
    earthclouds: 2,
    earthcloudtrans: 3,
    earthwater: 4,
    earthbump: 5,
  };

  texturefilenames = [
    "../textures/earthday.jpg",
    "../textures/earthnight.jpg",
    "../textures/earthclouds.jpg",
    "../textures/earthcloudtrans.jpg",
    "../textures/earthwater.jpg",
    "../textures/earthbump.jpg",
  ];

  return [layout, uniforms, texturefilenames];
}

function main(glsl) {
  let canvas = document.getElementById("canvas");
  let gl = webgl(canvas);
  let [layout, uniforms, texturefilenames] = shaderlayout();
  let basicshader = createprogram(gl, layout, glsl[0], glsl[1]);
  gl.useProgram(basicshader);
  bindtextures(gl, texturefilenames);
  bindclipspacequad(gl, basicshader);

  let animstart = performance.now();
  let animframe = requestAnimationFrame(animate);
  function animate(timestamp) {
    uniforms.iTime = (timestamp - animstart) / 1000;
    draw(gl, basicshader, uniforms);
    animframe = requestAnimationFrame(animate);
  }
}

window.onload = setup();
