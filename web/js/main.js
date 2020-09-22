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

function linkslider(name, v, i) {
  let slider = document.getElementById(name);
  slider.oninput = () => {
    v[i] = slider.value;
  };
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
  linkslider("upperbody0", upperbody, 0);
  linkslider("upperbody1", upperbody, 1);
  linkslider("upperbody2", upperbody, 2);

  let lowerbody = new Float32Array(uniforms.skel.buffer, 1 * L, 3);
  linkslider("lowerbody0", lowerbody, 0);
  linkslider("lowerbody1", lowerbody, 1);
  linkslider("lowerbody2", lowerbody, 2);

  let neck = new Float32Array(uniforms.skel.buffer, 2 * L, 3);
  linkslider("neck0", neck, 0);
  linkslider("neck1", neck, 1);
  linkslider("neck2", neck, 2);

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
    let t = 1.0 * uniforms.iTime;
    //let flex = sin(t)
    let flex = 0; //sin(t);
    let bend = sin(t);
    let rot = sin(t);

    //upperbody[0] = orientation[0];
    //upperbody[1] = orientation[1];
    //upperbody[2] = orientation[2];

    lefthip[0] = hip[0] + hip[1] * flex;
    lefthip[1] = hip1[0] + hip1[1] * bend;

    //Ranges of motions
    //neck[0] = neck0[0] + neck0[1] * flex;
    //neck[1] = neck1[0] + neck1[1] * bend;

    head[0] = head0[0] + head0[1] * flex;
    head[2] = head2[0] + head2[1] * rot;

    //lowerbody[0] = lowerbody0[0] + lowerbody0[1] * flex;
    //lowerbody[2] = lowerbody2[0] + lowerbody2[1] * rot;

    leftknee[0] = knee[0] + knee[1] * flex;
    leftfoot[0] = foot[0] + foot[1] * flex;

    leftshoulder[0] = shoulder[0] + shoulder[1] * flex;
    leftshoulder[1] = shoulder1[0] + shoulder1[1] * bend;
    leftelbow[0] = elbow[0] + elbow[1] * flex;
    lefthand[0] = hand[0] + hand[1] * flex;

    rightshoulder[1] = shoulder1[0] + shoulder1[1] * bend;
    righthand[0] = hand[0] + hand1[0] * flex;
    righthand[1] = hand1[0] + hand1[1] * bend;
    rightshoulder[2] = shoulder2[0] + shoulder2[1] * rot;

    rightelbow[2] = elbow2[0] + elbow2[1] * rot;

    draw(gl, basicshader, uniforms);
    animframe = requestAnimationFrame(animate);
  }
}

//Ranges of motion: [center, rad]
//PITCH
//aka FLEX/EXTEND direction
const lowerbody0 = [0.0, 0.7853981633974483];
const head0 = [0.0, -0.5];
const neck0 = [0.0, -0.5];
const hip = [0.4363323129985824, 0.9599310885968813];
const knee = [-1.0908307824964558, -1.2653637076958888];
const foot = [-0.2617993877991494, 0.6108652381980153];
const shoulder = [0.0, -1.5];
const elbow = [-1.2217304763960306, -1.3962634015954636];
const hand = [0.08726646259971647, -0.4363323129985824];

//YAW
//aka lateral bend direction
const neck1 = [0.0, -0.5];
const shoulder1 = [-0.6981317007977318, -1.0];
const hand1 = [0.08726646259971647, -1.3089969389957472];
const hip1 = [-0.6108652381980153, -0.7853981633974483];

//ROLL
//aka rotate direction
const head2 = [0.0, -1.0471975511965976];
const shoulder2 = [0.0, 1.3962634015954636];
const elbow2 = [0.0, 1.3962634015954636];
const lowerbody2 = [0.0, -0.7853981633974483];

window.onload = setup();
