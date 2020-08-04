async function fetchassets() {
  return await Promise.all([
    fetch("../glsl/common.glsl").then((res) => res.text()),
    fetch("../glsl/basic.glsl").then((res) => res.text()),
  ]);
}

function clipspacequad() {
  let model = {
    index: new Uint32Array([0, 1, 2, 2, 3, 0]),
    clipspace: new Float32Array([-1, -1, 0, 1, -1, 0, 1, 1, 0, -1, 1, 0]),
  };
  return model;
}

function setup() {
  fetchassets().then((assets) => main(assets));
}

function main(assets) {
  let canvas = document.getElementById("canvas");
  let gl = webgl(canvas);
  let [layout, uniforms] = shaderlayout();
  let basicshader = createprogram(gl, layout, assets[0], assets[1]);
  gl.useProgram(basicshader);
  let model = clipspacequad();
  bindmodel(gl, basicshader, model);

  let animstart = performance.now();
  let animframe = requestAnimationFrame(animate);
  function animate(timestamp) {
    uniforms.t = (timestamp - animstart) / 1000;
    draw(gl, basicshader, uniforms);
    animframe = requestAnimationFrame(animate);
  }
}

window.onload = setup();
