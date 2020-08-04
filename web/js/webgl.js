function webgl(canvas) {
  let gl = canvas.getContext("webgl2");
  gl || alert("You need a browser with webgl2. Try Firefox or Chrome.");
  gl.viewport(0, 0, canvas.width, canvas.height);
  gl.clearColor(0, 0, 0, 1);
  return gl;
}

function shaderlayout() {
  let layout = {};
  layout.attributes = {
    clipspace: 2,
  };

  layout.uniforms = {
    t: "uniform1f",
  };

  let uniforms = {
    t: 1.0,
  };

  return [layout, uniforms];
}

function draw(gl, program, uniforms) {
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  setuniforms(gl, program, uniforms);
  gl.drawElements(gl.TRIANGLES, 4, gl.UNSIGNED_INT, 0);
}

function setuniforms(gl, program, uniforms) {
  for (let name in program.uniforms) {
    gl[program.uniforms[name].func](program.uniforms[name].loc, uniforms[name]);
  }
}

function bindmodel(gl, program, model) {
  gl.bindVertexArray(gl.createVertexArray());
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, gl.createBuffer());
  gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, model["index"], gl.STATIC_DRAW);
  for (let name in model) {
    if (name != "index") {
      gl.enableVertexAttribArray(program.attributes[name].loc);
      gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
      gl.vertexAttribPointer(
        program.attributes[name].loc,
        program.attributes[name].sz,
        gl.FLOAT,
        false,
        0,
        0
      );
      gl.bufferData(gl.ARRAY_BUFFER, model[name], gl.STATIC_DRAW);
    }
  }
}

function createprogram(gl, layout, common, text) {
  let verttext = common.concat("\n#define VERT;\n", text);
  let fragtext = common.concat("\n#define FRAG;\n", text);

  let vert = gl.createShader(gl.VERTEX_SHADER);
  gl.shaderSource(vert, verttext);
  gl.compileShader(vert);

  let frag = gl.createShader(gl.FRAGMENT_SHADER);
  gl.shaderSource(frag, fragtext);
  gl.compileShader(frag);

  let program = gl.createProgram();
  gl.attachShader(program, vert);
  gl.attachShader(program, frag);
  gl.linkProgram(program);

  program.attributes = getattributes(gl, program, layout.attributes);
  console.log("program.attributes: ", program.attributes);
  console.log("layout.attributes: ", layout.attributes);
  program.uniforms = getuniforms(gl, program, layout.uniforms);
  console.log("program.uniforms: ", program.uniforms);
  return program;
}

function getattributes(gl, program, layout) {
  let attributes = {};
  for (let name in layout) {
    let loc = gl.getAttribLocation(program, name);
    if (loc != -1) {
      attributes[name] = { loc: loc, sz: layout[name] };
    }
  }
  return attributes;
}

function getuniforms(gl, program, layout) {
  let uniforms = {};
  for (let name in layout) {
    let loc = gl.getUniformLocation(program, name);
    if (loc != null) {
      uniforms[name] = { loc: loc, func: layout[name] };
    }
  }
  return uniforms;
}
