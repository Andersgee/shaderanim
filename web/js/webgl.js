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
    earthday: "uniform1i",
    earthnight: "uniform1i",
  };

  let uniforms = {
    t: 1.0,
    earthday: 0,
    earthnight: 1,
  };

  return [layout, uniforms];
}

function draw(gl, program, uniforms) {
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  setuniforms(gl, program, uniforms);
  gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, 0);
}

function setuniforms(gl, program, uniforms) {
  for (let name in program.uniforms) {
    gl[program.uniforms[name].func](program.uniforms[name].loc, uniforms[name]);
  }
}

function clipspacequad() {
  let model = {
    index: new Uint32Array([0, 1, 2, 2, 3, 0]),
    clipspace: new Float32Array([-1, -1, 1, -1, 1, 1, -1, 1]),
  };
  return model;
}

function bindclipspacequad(gl, program) {
  let model = clipspacequad();
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

function createtextures(gl, filenames) {
  //use single black pixel in textures (temporarily, before images are loaded)
  gl.activeTexture(gl.TEXTURE0 + 0);
  let tex0 = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, tex0);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

  gl.texImage2D(
    gl.TEXTURE_2D,
    0,
    gl.RGBA,
    1,
    1,
    0,
    gl.RGBA,
    gl.UNSIGNED_BYTE,
    new Uint8Array([0, 0, 0, 255])
  );

  gl.activeTexture(gl.TEXTURE0 + 1);
  let tex1 = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, tex1);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

  gl.texImage2D(
    gl.TEXTURE_2D,
    0,
    gl.RGBA,
    1,
    1,
    0,
    gl.RGBA,
    gl.UNSIGNED_BYTE,
    new Uint8Array([0, 0, 0, 255])
  );

  let image0 = new Image();
  image0.src = filenames[0];
  image0.onload = () => {
    gl.activeTexture(gl.TEXTURE0 + 0);
    gl.bindTexture(gl.TEXTURE_2D, tex0);
    let mipLevel = 0;
    let internalFormat = gl.RGBA;
    let srcFormat = gl.RGBA;
    let srcType = gl.UNSIGNED_BYTE;
    gl.texImage2D(
      gl.TEXTURE_2D,
      mipLevel,
      internalFormat,
      srcFormat,
      srcType,
      image0
    );
  };

  let image1 = new Image();
  image1.src = filenames[1];
  image1.onload = () => {
    gl.activeTexture(gl.TEXTURE0 + 1);
    gl.bindTexture(gl.TEXTURE_2D, tex1);
    let mipLevel = 0;
    let internalFormat = gl.RGBA;
    let srcFormat = gl.RGBA;
    let srcType = gl.UNSIGNED_BYTE;
    gl.texImage2D(
      gl.TEXTURE_2D,
      mipLevel,
      internalFormat,
      srcFormat,
      srcType,
      image1
    );
  };
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
  program.uniforms = getuniforms(gl, program, layout.uniforms);
  console.log("program: ", program);

  createtextures(gl, [
    "../textures/earthday.jpg",
    "../textures/earthnight.jpg",
  ]);

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
