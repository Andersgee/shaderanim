async function fetchglsl() {
  return await Promise.all([
    fetch("../glsl/common.glsl").then((res) => res.text()),
    //fetch("../glsl/earth.glsl").then((res) => res.text()),
    //fetch("../glsl/hills.glsl").then((res) => res.text()),
    //fetch("../glsl/olympian.glsl").then((res) => res.text()),
    fetch("../glsl/primitives.glsl").then((res) => res.text()),
  ]);
}

function setup() {
  fetchglsl().then((glsl) => main(glsl));
}

function shaderlayout(canvas) {
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
    skel: "uniform3fv",
    bodyroot: "uniform3fv",
  };

  let uniforms = {
    iTime: 0.0,
    iResolution: [canvas.width, canvas.height],
    earthday: 0,
    earthnight: 1,
    earthclouds: 2,
    earthcloudtrans: 3,
    earthwater: 4,
    earthbump: 5,
    skel: new Float32Array(16 * 3).fill(0.0),
    bodyroot: [0, 1.8, 0],
  };
  /*
  uniforms.skel[0 * 3 + 0] = 0.25;
  uniforms.skel[0 * 3 + 1] = 0.5;
  uniforms.skel[0 * 3 + 2] = 0.1;
  uniforms.skel[4 * 3 + 0] = 0.5;
*/
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

function sin(x) {
  return Math.sin(x);
}

function main(glsl) {
  let canvas = document.getElementById("canvas");
  canvas.width = 720;
  canvas.height = 480;
  let gl = webgl(canvas);
  let [layout, uniforms, texturefilenames] = shaderlayout(canvas);
  let basicshader = createprogram(gl, layout, glsl[0], glsl[1]);
  gl.useProgram(basicshader);
  bindtextures(gl, texturefilenames);
  bindclipspacequad(gl, basicshader);

  let L = 12;
  let upperbody = new Float32Array(uniforms.skel.buffer, 0 * L, 3);
  let lowerbody = new Float32Array(uniforms.skel.buffer, 1 * L, 3);
  let neck = new Float32Array(uniforms.skel.buffer, 2 * L, 3);
  let head = new Float32Array(uniforms.skel.buffer, 3 * L, 3);
  let rightshoulder = new Float32Array(uniforms.skel.buffer, 4 * L, 3);
  let rightelbow = new Float32Array(uniforms.skel.buffer, 5 * L, 3);
  let righthand = new Float32Array(uniforms.skel.buffer, 6 * L, 3);
  let leftshoulder = new Float32Array(uniforms.skel.buffer, 7 * L, 3);
  let leftelbow = new Float32Array(uniforms.skel.buffer, 8 * L, 3);
  let lefthand = new Float32Array(uniforms.skel.buffer, 9 * L, 3);

  let righthip = new Float32Array(uniforms.skel.buffer, 10 * L, 3);
  let lefthip = new Float32Array(uniforms.skel.buffer, 13 * L, 3);
  let leftknee = new Float32Array(uniforms.skel.buffer, 14 * L, 3);
  let leftfoot = new Float32Array(uniforms.skel.buffer, 15 * L, 3);

  let animstart = performance.now();
  let animframe = requestAnimationFrame(animate);
  function animate(timestamp) {
    uniforms.iTime = (timestamp - animstart) / 1000;
    let t = 0.5 * uniforms.iTime;
    //Ranges of motions
    //neck[0] = neck0[0] + neck0[1] * sin(t);
    neck[1] = neck1[0] + neck1[1] * sin(t);

    //head[0] = head0[0] + head0[1] * sin(t);
    //head[2] = head2[0] + head2[1] * sin(t);

    lowerbody[0] = body[0] + body[1] * sin(t);
    lefthip[0] = hip[0] + hip[1] * sin(t);
    leftknee[0] = knee[0] + knee[1] * sin(t);
    leftfoot[0] = foot[0] + foot[1] * sin(t);

    leftshoulder[0] = shoulder[0] + shoulder[1] * sin(t);
    leftelbow[0] = elbow[0] + elbow[1] * sin(t);
    lefthand[0] = hand[0] + hand[1] * sin(t);

    rightshoulder[1] = shoulder1[0] + shoulder1[1] * sin(t);
    righthand[1] = hand1[0] + hand1[1] * sin(t);
    rightshoulder[2] = shoulder2[0] + shoulder2[1] * sin(t);
    rightelbow[2] = elbow2[0] + elbow2[1] * sin(t);

    draw(gl, basicshader, uniforms);
    animframe = requestAnimationFrame(animate);
  }
}

//Ranges of motion: [center, rad]
//PITCH
const head0 = [0.0, 0.5];
const neck0 = [0.0, 0.75];
const body = [0.0, 0.7853981633974483];
const hip = [0.4363323129985824, 0.9599310885968813];
const knee = [-1.0908307824964558, 1.2653637076958888];
const foot = [-0.2617993877991494, 0.6108652381980153];
const shoulder = [0.0, 1.5];
const elbow = [-1.2217304763960306, 1.3962634015954636];
const hand = [0.08726646259971647, 0.4363323129985824];

//YAW
const neck1 = [0.0, 0.5];
const shoulder1 = [-0.6981317007977318, 1.0];
const hand1 = [0.08726646259971647, 1.3089969389957472];

//ROLL
const head2 = [0.0, 1.0471975511965976];
const shoulder2 = [0.0, 1.3962634015954636];
const elbow2 = [0.0, 1.3962634015954636];

window.onload = setup();
