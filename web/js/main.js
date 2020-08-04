async function fetchassets() {
  return await Promise.all([
    fetch("../glsl/common.glsl").then((res) => res.text()),
    fetch("../glsl/basic.glsl").then((res) => res.text()),
  ]);
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
  bindclipspacequad(gl, basicshader);

  let animstart = performance.now();
  let animframe = requestAnimationFrame(animate);
  function animate(timestamp) {
    uniforms.t = (timestamp - animstart) / 1000;
    draw(gl, basicshader, uniforms);
    animframe = requestAnimationFrame(animate);
  }
}

window.onload = setup();
