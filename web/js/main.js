//Ranges of motion: [center, rad]
//PITCH
//aka FLEX/EXTEND direction
const rom_lowerbody0 = [0.0, 0.7853981633974483];
const rom_head0 = [0.0, 0.5];
const rom_neck0 = [0.0, 0.5];
const rom_hip0 = [0.4363323129985824, 0.9599310885968813];
const rom_knee0 = [-1.0908307824964558, -1.2653637076958888];
const rom_foot0 = [-0.2617993877991494, 0.6108652381980153];
const rom_shoulder0 = [0.0, -1.5];
const rom_elbow0 = [-1.2217304763960306, -1.3962634015954636];
const rom_hand0 = [0.08726646259971647, -1.3089969389957472];
//YAW

//aka lateral bend direction
const rom_neck1 = [0.0, -0.5];
const rom_shoulder1 = [-0.6981317007977318, -1.0];
const rom_hand1 = [0.08726646259971647, -0.4363323129985824];
const rom_hip1 = [-0.6108652381980153, -0.7853981633974483];

//ROLL
//aka rotate direction
const rom_head2 = [0.0, -1.0471975511965976];
const rom_shoulder2 = [0.0, 1.3962634015954636];
const rom_hand2 = [0.0, 1.3962634015954636];
const rom_lowerbody2 = [0.0, -0.7853981633974483];

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
    skel: "uniform3fv",
    bodyroot: "uniform3fv",
    earthday: "uniform1i",
    earthnight: "uniform1i",
  };

  let uniforms = {
    iTime: 0.0,
    iResolution: [canvas.width, canvas.height],
    skel: new Float32Array(16 * 3).fill(0.0),
    bodyroot: [0, 1.8, 0],
    earthday: 0,
    earthnight: 1,
  };

  texturefilenames = ["../textures/earthday.jpg", "../textures/earthnight.jpg"];

  return [layout, uniforms, texturefilenames];
}

function sin(x) {
  return Math.sin(x);
}

function linkslider(name, v, i, rom = [0, 1]) {
  let slider = document.getElementById(name);
  slider.type = "range";
  slider.min = "-1";
  slider.max = "1";
  slider.value = "0";
  slider.step = "0.01";
  slider.oninput = () => {
    v[i] = rom[0] + rom[1] * slider.value;
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
  linkslider("lowerbody0", lowerbody, 0, rom_lowerbody0);
  //linkslider("lowerbody1", lowerbody, 1);
  linkslider("lowerbody2", lowerbody, 2, rom_lowerbody2);

  let neck = new Float32Array(uniforms.skel.buffer, 2 * L, 3);
  linkslider("neck0", neck, 0, rom_neck0);
  linkslider("neck1", neck, 1, rom_neck1);
  //linkslider("neck2", neck, 2);

  let head = new Float32Array(uniforms.skel.buffer, 3 * L, 3);
  linkslider("head0", head, 0, rom_head0);
  //linkslider("head1", head, 1);
  linkslider("head2", head, 2, rom_head2);

  let rightshoulder = new Float32Array(uniforms.skel.buffer, 4 * L, 3);
  linkslider("rightshoulder0", rightshoulder, 0, rom_shoulder0);
  linkslider("rightshoulder1", rightshoulder, 1, rom_shoulder1);
  linkslider("rightshoulder2", rightshoulder, 2, rom_shoulder2);

  let rightelbow = new Float32Array(uniforms.skel.buffer, 5 * L, 3);
  linkslider("rightelbow0", rightelbow, 0, rom_elbow0);
  //linkslider("rightelbow1", rightelbow, 1);
  //linkslider("rightelbow2", rightelbow, 2, rom_elbow2);

  let righthand = new Float32Array(uniforms.skel.buffer, 6 * L, 3);
  linkslider("righthand0", righthand, 0, rom_hand0);
  linkslider("righthand1", righthand, 1, rom_hand1);
  linkslider("righthand2", righthand, 2, rom_hand2);

  let leftshoulder = new Float32Array(uniforms.skel.buffer, 7 * L, 3);
  linkslider("leftshoulder0", leftshoulder, 0, rom_shoulder0);
  linkslider("leftshoulder1", leftshoulder, 1, rom_shoulder1);
  linkslider("leftshoulder2", leftshoulder, 2, rom_shoulder2);

  let leftelbow = new Float32Array(uniforms.skel.buffer, 8 * L, 3);
  linkslider("leftelbow0", leftelbow, 0, rom_elbow0);
  //linkslider("leftelbow1", leftelbow, 1);
  //linkslider("leftelbow2", leftelbow, 2, rom_elbow2);

  let lefthand = new Float32Array(uniforms.skel.buffer, 9 * L, 3);
  linkslider("lefthand0", lefthand, 0, rom_hand0);
  linkslider("lefthand1", lefthand, 1, rom_hand1);
  linkslider("lefthand2", lefthand, 2, rom_hand2);

  let righthip = new Float32Array(uniforms.skel.buffer, 10 * L, 3);
  linkslider("righthip0", righthip, 0, rom_hip0);
  linkslider("righthip1", righthip, 1, rom_hip1);
  linkslider("righthip2", righthip, 2);

  let rightknee = new Float32Array(uniforms.skel.buffer, 11 * L, 3);
  linkslider("rightknee0", rightknee, 0, rom_knee0);
  linkslider("rightknee1", rightknee, 1);
  linkslider("rightknee2", rightknee, 2);

  let rightfoot = new Float32Array(uniforms.skel.buffer, 12 * L, 3);
  linkslider("rightfoot0", rightfoot, 0, rom_foot0);
  linkslider("rightfoot1", rightfoot, 1);
  linkslider("rightfoot2", rightfoot, 2);

  let lefthip = new Float32Array(uniforms.skel.buffer, 13 * L, 3);
  linkslider("lefthip0", lefthip, 0, rom_hip0);
  linkslider("lefthip1", lefthip, 1, rom_hip1);
  linkslider("lefthip2", lefthip, 2);

  let leftknee = new Float32Array(uniforms.skel.buffer, 14 * L, 3);
  linkslider("leftknee0", leftknee, 0);
  linkslider("leftknee1", leftknee, 1);
  linkslider("leftknee2", leftknee, 2);

  let leftfoot = new Float32Array(uniforms.skel.buffer, 15 * L, 3);
  linkslider("leftfoot0", leftfoot, 0, rom_knee0);
  linkslider("leftfoot1", leftfoot, 1);
  linkslider("leftfoot2", leftfoot, 2);

  let animstart = performance.now();

  function animate(timestamp) {
    uniforms.iTime = (timestamp - animstart) / 1000;
    /*
    
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

    //head[0] = head0[0] + head0[1] * flex;
    //head[2] = head2[0] + head2[1] * rot;

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
*/
    draw(gl, basicshader, uniforms);
    animframe = requestAnimationFrame(animate);
  }

  let animframe = requestAnimationFrame(animate);
}

window.onload = setup();
