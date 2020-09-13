#ifdef VERT

in vec2 clipspace;

out vec2 ssc;

void main() {
  ssc = clipspace;
  gl_Position = vec4(ssc, 0.0, 1.0);
}

#endif

///////////////////////////////////////////////////////////////////////////////

#ifdef FRAG

in vec2 ssc;
uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

#define s(a, b, x) smoothstep(a, b, x)
#define rot(a) mat2(cos(a + PI*0.5*vec4(0,1,3,0)))
#define Z min(0, iFrame)

// simpler, easier version to compile of the dude
// #define SIMPLE_HUMAN

// hash functions by Dave_Hoskins
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(.1031, .1030, .0973, .1099)

// skeleton, represented as pitch/yaw/roll rotations
vec3 skel[16];

float getHead( in vec3 p ) {
    vec3 brainDim = vec3(0.2, 0.23, 0.22);
    vec3 inBrain = p - vec3(0, 0.27, 0.0);
    float brain = sdEllipsoid(inBrain, brainDim);
    
    vec3 faceDim = vec3(0.04, 0.19, 0.03);
    faceDim.x += sin(p.y*5.0)*0.05;
    faceDim.z += cos(p.x*15.0)*0.02;
    faceDim.z += sin(p.y*6.0)*0.03;
    vec3 inFace = p - vec3(0, 0.18, 0.11);
    float face = sdBox(inFace, faceDim) - 0.1;
    
    float d = brain;
    d = smin(d, face, 0.1);
    return d;
}

float getUpperArm( in vec3 p ) {
    vec3 shoulderDim = vec3(0.23, 0.15, 0.18);
    float shoulder = sdEllipsoid(p - vec3(0.05, 0.05, 0.0), shoulderDim);
    
    float muscle1Rad = 0.09;
    muscle1Rad -= cos(p.x*8.0)*0.02;
    vec3 muscle1Pos1 = vec3(0.0, 0.05, 0.03);
    vec3 muscle1Pos2 = vec3(0.74, 0.05, 0.03);
    float muscle1 = sdCapsule(p, muscle1Pos1, muscle1Pos2, muscle1Rad);
    
    float muscle2Rad = 0.09;
    muscle2Rad += sin(p.x*7.0)*0.02;
    vec3 muscle2Pos1 = vec3(0.0, -0.04, -0.03);
    vec3 muscle2Pos2 = vec3(0.78, -0.02, -0.03);
    float muscle2 = sdCapsule(p, muscle2Pos1, muscle2Pos2, muscle2Rad);
    
    float d = shoulder;
    d = smin(d, muscle1, 0.03);
    d = smin(d, muscle2, 0.03);
    return d;
}

float getForearm( in vec3 p ) {
    const vec3 handPos = vec3(0.58, 0, 0);
    float rad = 0.06 + sin(p.x*9.0)*0.01;
    float muscle1 = sdCapsule(p, vec3(0.06, 0.06, 0.0), handPos+vec3(0, 0.05, 0), rad);
    float muscle2 = sdCapsule(p, vec3(0.04, -0.02, 0.03), handPos+vec3(0, -0.01, 0), rad);
    float elbow = length(p)-0.08;
    float d = muscle1;
    d = smin(d, muscle2, 0.03);
    d = smin(d, elbow, 0.05);
    return d;
}

float getHand( in vec3 p ) {
    vec3 handDim = vec3(0.08, 0.07, 0.01);
    float cu1 = cos(p.y*11.0-0.3);
	handDim.x += cu1*0.06;
    handDim.z += cu1*0.03;
    handDim.z -= sin(p.x*4.0)*0.05;
    float hand = sdBox(p - vec3(0.25, 0.02, 0.0), handDim) - 0.05;
    float thumb = sdCapsule(p, vec3(0.1, 0.02, 0.03), vec3(0.15, 0.18, 0.06), 0.04);
    float d = hand;
    d = smin(d, thumb, 0.07);
    return d;
}

float getUpperLeg( in vec3 p ) {
    const vec3 kneePos = vec3(0, -1.01, 0);
    float muscle1Rad = 0.15 - sin(p.y*4.0)*0.03;
    float muscle1 = sdCapsule(p, vec3(0.03, 0.0, 0.1), kneePos, muscle1Rad);
    float muscle2 = sdCapsule(p, vec3(-0.12, 0.0, -0.05), kneePos, muscle1Rad);
    float knee = sdEllipsoid(p - vec3(0, -0.95, 0.03), vec3(0.12, 0.2, 0.12));
    float d = muscle1;
    d = smin(d, muscle2, 0.02);
    d = smin(d, knee, 0.03);
    
    return d;
}

float getLowerLeg( in vec3 p ) {
    const vec3 footPos = vec3(0, -1.06, -0.08);
    float muscle1Rad = 0.1 - sin(p.y*4.0)*0.03;
    float muscle1 = sdCapsule(p, vec3(0.02, 0.0, 0.0), footPos, muscle1Rad);
    float muscle2Rad = 0.09 - sin(p.y*5.3)*0.05;
    float muscle2 = sdCapsule(p, vec3(-0.02, 0.04, -0.08), footPos + vec3(0.0, 0.04, -0.02), muscle2Rad);
    float d = muscle1;
    d = smin(d, muscle2, 0.02);
    return d;    
}

float getFoot( in vec3 p ) {
    vec3 footDim = vec3(0.04, 0.0, 0.19);
    footDim.x -= cos(p.z*13.0-0.4)*0.04;
    footDim.z += cos(p.x*14.0+0.2)*0.05;
    vec3 inFoot = p - vec3(0.03, -0.13, 0.19);
    float foot = sdBox(inFoot, footDim)-0.05;
    float ankle = sdEllipsoid(inFoot - vec3(0.0, 0.07, -0.13), vec3(0.1, 0.08, 0.18));
    float d = foot;
    d = smin(d, ankle, 0.1);
    return d;
}


/*
vec2 hash21( in float p ) {
	vec3 p3 = fract(vec3(p) * HASHSCALE3);
	p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec2 hash22( vec2 p ) {
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec2 hash23( in vec3 p3 ) {
	p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec3 hash31( in float p ) {
   vec3 p3 = fract(vec3(p) * HASHSCALE3);
   p3 += dot(p3, p3.yzx+19.19);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

vec3 hash32( in vec2 p ) {
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

vec3 hash33( in vec3 p3 ) {
	p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

vec4 hash41( in float p ) {
	vec4 p4 = fract(vec4(p) * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

vec4 hash42( in vec2 p ) {
	vec4 p4 = fract(vec4(p.xyxy) * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

vec4 hash43( in vec3 p ) {
	vec4 p4 = fract(vec4(p.xyzx)  * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

vec4 hash44( in vec4 p4 ) {
	p4 = fract(p4  * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

// return sequence id and time in this sequence
void getSequence( in float time, out int seqID, out float seqTime ) {
    
    seqID = 0;
    seqTime = time;
    
    if (time < 34.0) {
        seqID = 0;
        seqTime = time;
    } else if (time < 64.0) {
        seqID = 1;
        seqTime = time-34.0;
    } else if (time < 74.0) {
        seqID = 2;
        seqTime = time-64.0;
    } else if (time < 94.0) {
        seqID = 3;
        seqTime = time-74.0;
    } else if (time < 104.0) {
        seqID = 4;
        seqTime = time-94.0;
    } else if (time < 144.0) {
        seqID = 5;
        seqTime = time-104.0;
    } else {
        seqID = 6;
        seqTime = time-144.0;
    }

}

// 0  = upper body
// 1  = lower body
// 2  = neck
// 3  = head
// 4  = right shoulder
// 5  = right elbow
// 6  = right hand
// 7  = left shoulder
// 8  = left elbow
// 9  = left hand
// 10 = right hip
// 11 = right knee
// 12 = right foot
// 13 = left hip
// 14 = left knee
// 15 = left foot


// normal function, call de() in a for loop for faster compile times.
vec3 getNormal(vec3 p) {
    vec4 n = vec4(0);
    for (int i = Z ; i < 4 ; i++) {
        vec4 s = vec4(p, 0);
        s[i] += 0.001;
        n[i] = de(s.xyz);
    }
    return normalize(n.xyz-n.w);
}
*/

float hash11( in float p ) {
	vec3 p3 = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash12( in vec2 p ) {
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13( in vec3 p3 ) {
	p3  = fract(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// 1D perlin, between -1 and 1
float perlin( in float x, in float seed ) {
    x += hash11(seed);
    float a = floor(x);
    float b = a + 1.0;
    float f = fract(x);
    a = hash12(vec2(seed, a));
    b = hash12(vec2(seed, b));
    f = f*f*(3.0-2.0*f);
    return mix(a, b, f)*2.0-1.0;
}

// rotate an arm
vec3 rotateArm(vec3 p, int i ) {
    vec3 pitchYawRoll = skel[i];
    p.xz *= rot(pitchYawRoll.y);
    p.xy *= rot(pitchYawRoll.x);
    p.yz *= rot(pitchYawRoll.z);
    return p;
}

// initialize skeleton
void initSkel(in int seqID, in float seqTime, in float time) {
    for (int i = 0 ; i < skel.length() ; i++) {
        skel[i] = vec3(0);
    }
    
    float pTime = time*0.3;
    float p0 = perlin(pTime, 0.0)*0.2;
    float p1 = perlin(pTime, 1.0)*0.2;
    float p2 = perlin(pTime, 2.0)*0.2;
    float p3 = perlin(pTime, 3.0)*0.2;
    float p4 = perlin(pTime, 4.0)*0.2;
    float p5 = perlin(pTime, 5.0)*0.2;
    float p6 = perlin(pTime, 6.0)*0.2;
    float p7 = perlin(pTime, 7.0)*0.2;
        
    // appear
    skel[2] = vec3(0.1, 0, 0);
    skel[3] = vec3(0.2, 0, 0);
    skel[4] = vec3(0.2, 0, 0);
    skel[7] = vec3(0.2, 0, 0);
    skel[10] = vec3(0.3, 0.7, 0);
    skel[13] = vec3(0.3, 0.7, 0);
    
    // float around
    float f1 = s(8.0, 10.0, seqTime);
    skel[1] = mix(skel[1], vec3(-0.1, 0, 0), f1);
    skel[2] = mix(skel[2], vec3(0.1, 0, 0), f1);
    skel[3] = mix(skel[3], vec3(0.1, 0, 0), f1);
    skel[4] = mix(skel[4], vec3(1.2 + p0, 0, -0.7), f1);
    skel[5] = mix(skel[5], vec3(0, -0.3 + p1, 0), f1);
    skel[6] = mix(skel[6], vec3(0, -0.2, 0), f1);
    skel[7] = mix(skel[7], vec3(1.2 + p2, 0, -0.2), f1);
    skel[8] = mix(skel[8], vec3(0, -0.5 + p3, 0), f1);
    skel[9] = mix(skel[9], vec3(0, -0.2, 0), f1);
    skel[10] = mix(skel[10], vec3(0.8 + p4, 0.2, 0), f1);
    skel[11] = mix(skel[11], vec3(-0.6 + p5, 0, 0), f1);
    skel[12] = mix(skel[12], vec3(-0.6, 0, 0), f1);
    skel[13] = mix(skel[13], vec3(0.7 + p6, 0.2, 0), f1);
    skel[14] = mix(skel[14], vec3(-0.6 + p7, 0, 0), f1);
    skel[15] = mix(skel[15], vec3(-0.6, 0, 0), f1);
    
    // look at his arms
    float f2 = s(10.0, 16.0, seqTime) - s(15.0, 20.0, seqTime);
    skel[2] = mix(skel[2], vec3(-0.3, 0, 0), f2);
    skel[3] = mix(skel[3], vec3(-0.4, -0.5, 0), f2);
    skel[4] = mix(skel[4], vec3(0.8, -0.9, 0), f2);
    skel[5] = mix(skel[5], vec3(0.0, -1.0, 0), f2);
    skel[6] = mix(skel[6], vec3(0.0, -0.3, 0), f2);
    float f3 = s(18.0, 22.0, seqTime) - s(26.0, 28.0, seqTime);
    skel[2] = mix(skel[2], vec3(-0.3, 0, 0), f3);
    skel[3] = mix(skel[3], vec3(-0.4, 0.5, 0), f3);
    skel[7] = mix(skel[7], vec3(0.8, -0.9, 0), f3);
    skel[8] = mix(skel[8], vec3(0.0, -1.0, 0), f3);
    skel[9] = mix(skel[9], vec3(0.0, -0.3, 0), f3);
    
    // go into flying
    float f4 = s(31.5, 34.0, seqTime);
    skel[0] = mix(skel[0], vec3(-1.2, 0, 0), f4);
    skel[1] = mix(skel[1], vec3(-0.4, 0, 0), f4);
    skel[2] = mix(skel[2], vec3(0.3, 0, 0), f4);
    skel[3] = mix(skel[3], vec3(0.4, 0, 0), f4);
    skel[4] = mix(skel[4], vec3(1.2, 0.3, 0), f4);
    skel[7] = mix(skel[7], vec3(1.2, 0.3, 0), f4);
    skel[10] = mix(skel[10], vec3(-0.3, -0.3, 0.3), f4);
    skel[11] = mix(skel[11], vec3(-0.1, 0, 0), f4);
    skel[12] = mix(skel[12], vec3(-0.6, 0, 0), f4);
    skel[13] = mix(skel[13], vec3(-0.2, -0.3, 0.3), f4);
    skel[14] = mix(skel[14], vec3(-0.2, 0, 0), f4);
    skel[15] = mix(skel[15], vec3(-0.6, 0, 0), f4);
}

// camera direction and position
void getCamera(in vec2 uv, in int seqID, in float seqTime, out vec3 dir, out vec3 from){
    // look at and up vector
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 lookAt = vec3(0.0);
    from = vec3(0.0, 0.0, -1.0);
    
    // rotate around our dude
    up = normalize(vec3(1.0, 10.0, 2.0));
    lookAt = vec3(0.0);
    float rota = seqTime*0.1;
    from = vec3(cos(rota), 0.0, sin(rota))*5.0;
    
    // send our dude flying
    from.z -= s(31.7, 37.0, seqTime)*200.0;
    from.z -= s(30.5, 34.0, seqTime)*5.0;
    
    vec3 forward = normalize(lookAt - from);
    vec3 right = normalize(cross(forward, up));
    vec3 upward = cross(right, forward);
    
    float fov = 1.0;
    float dist = 0.5 / tan(fov*0.5);
    
    dir = normalize(forward*dist + right*uv.x + upward*uv.y);
}

// rotate a limb
vec3 rotateLimb( in vec3 p, in int i ) {
    vec3 pitchYawRoll = skel[i];
    p.xz *= rot(pitchYawRoll.y);
    p.yz *= rot(pitchYawRoll.x);
    p.xz *= rot(pitchYawRoll.z);
    return p;
}

float getTorso( in vec3 p ) {
    vec3 mainDim = vec3(0.35, 0.15, 0.05);
    mainDim.x -= cos(p.y*2.0+0.8)*0.19;
    mainDim.y -= cos(p.x*7.0)*0.05;
    vec3 inTorso = p - vec3(0, 0.15, 0.05);
    inTorso.z += s(-0.2, 0.5, inTorso.y)*0.2;
    float torso = sdBox(inTorso, mainDim) - 0.15;
    
    vec3 trapDim = vec3(0.15, 0.13, 0);
    vec3 inTrap = inTorso - vec3(0.2, 0.33, -0.07);
    inTrap.xy *= rot(0.4);
    inTrap.yz *= rot(-0.2);
    float trap = sdBox(inTrap, trapDim)-0.13;
    
    vec3 pecDim = vec3(0.11, 0.08, 0.0);
    pecDim.y += sin(inTorso.x*7.5)*0.05;
    vec3 inPec = inTorso - vec3(0.19, 0.2, 0.12);
    float pec = sdBox(inPec, pecDim) - 0.1;
    float pecMore = length(inPec)-0.15;
    pec = smin(pec, pecMore, 0.25);
    
    float spine = s(0.13, 0.0, p.x)*s(0.1, -0.3, p.z);
    
    float d = torso;
    d = smin(d, trap, 0.1);
    d = smin(d, pec, 0.05);
    d += spine*0.02;
    return d;
}

float getPelvis( in vec3 p ) {
    
    #ifdef SIMPLE_HUMAN
    return sdBox(p - vec3(0, -0.45, 0.08), vec3(0.13, 0.3, 0))-0.2;
    #endif
    
    vec3 mainDim = vec3(0.17, 0.3, 0);
    mainDim.x += sin(p.y*6.0)*0.04;
    vec3 inMain = p - vec3(0, -0.45, 0.07);
    inMain.z -= cos(inMain.y*6.0)*0.02;
    
    float main = sdBox(inMain, mainDim) - 0.2;
    
    vec3 absDim = vec3(0.13, 0.29, 0.0);
    absDim.z -= cos(p.x*30.0)*0.007;
    absDim.z -= cos(p.y*36.0)*0.007;
    vec3 inAbs = inMain - vec3(0, 0.1, 0.13);
    float absD = sdBox(inAbs, absDim)-0.1;
    
    vec3 penisDim = vec3(0.03, 0.05, 0.05);
    penisDim.x -= sin(p.y*10.0)*0.03;
    vec3 inPenis = p - vec3(0, -0.9, 0.13);
    inPenis.z += inPenis.y*0.2;
    float penis = sdBox(inPenis, penisDim)-0.12;
    
    float butt = sdEllipsoid(p - vec3(0.17, -0.75, -0.03),
                             vec3(0.2, 0.28, 0.2));
    
    float spine = s(0.1, 0.0, p.x)*s(0.1, -0.1, p.z);
    
    float d = main;
    d = smin(d, absD, 0.1);
    d = smin(d, penis, 0.1);
    d = smin(d, butt, 0.1);
    d += spine*0.02;
    return d;
}

float getNeck( in vec3 p ) {
    return sdCapsule(p, vec3(0), vec3(0, 0.24, 0.07), 0.15);
}

// main distance function
float de( in vec3 p ) {
    p.y += 0.5;
    // main pivot point is upper body
    vec3 inUpperBody = p;
    inUpperBody = rotateLimb(inUpperBody, 0);
    inUpperBody -= vec3(0, 1.3, 0);
    vec3 inLowerBody = inUpperBody;
    inLowerBody = rotateLimb(inLowerBody, 1);
    
    // keep upper body unflipped for the head
    vec3 inUpperBodyNoFlip = inUpperBody;
    // do some flipping
    int upperOffset = int(inUpperBody.x > 0.0)*3;
    int lowerOffset = int(inLowerBody.x > 0.0)*3;
    inUpperBody = vec3(abs(inUpperBody.x), inUpperBody.yz);
    inLowerBody = vec3(abs(inLowerBody.x), inLowerBody.yz);
    
    float torso = getTorso(inUpperBody);
    float pelvis = getPelvis(inLowerBody);
    
    // do the neck and head
    vec3 inNeck = inUpperBodyNoFlip - vec3(0, 0.68, -0.1);
    inNeck = rotateLimb(inNeck, 2);
    float neck = getNeck(inNeck);
    vec3 inHead = inNeck - vec3(0, 0.24, 0.07);
    inHead = rotateLimb(inHead, 3);
    
    float head = getHead(inHead);
    // do the arms
    vec3 inShoulder = inUpperBody - vec3(0.4, 0.48, -0.12);
    inShoulder = rotateArm(inShoulder, 4+upperOffset);
    float shoulder = getUpperArm(inShoulder);
    vec3 inElbow = inShoulder - vec3(0.79, 0, 0);
    inElbow = rotateArm(inElbow, 5+upperOffset);
    float elbow = getForearm(inElbow);
    vec3 inHand = inElbow - vec3(0.56, 0, 0);
    inHand = rotateArm(inHand, 6+upperOffset);
    float hand = getHand(inHand);
    
    // do the legs
    vec3 inHip = inLowerBody - vec3(0.25, -0.79, 0);
    inHip = rotateLimb(inHip, 10+lowerOffset);
    float hip = getUpperLeg(inHip);
    vec3 inKnee = inHip - vec3(0, -1.01, 0);
    inKnee = rotateLimb(inKnee, 11+lowerOffset);
    float knee = getLowerLeg(inKnee);
    vec3 inFoot = inKnee - vec3(0, -1.06, -0.08);
    inFoot = rotateLimb(inFoot, 12+lowerOffset);
    float foot = getFoot(inFoot);
    
    // blend the body together
    float d = torso;
    d = smin(d, pelvis, 0.2);
    d = smin(d, neck, 0.15);
    d = smin(d, head, 0.04);
    // blend the arms together
    float arms = shoulder;
    arms = smin(arms, elbow, 0.05);
    arms = smin(arms, hand, 0.05);
    // blend the legs together
    float legs = hip;
    legs = smin(legs, knee, 0.05);
    legs = smin(legs, foot, 0.1);
    // blend everything and return the value
    d = smin(d, arms, 0.1);
    d = smin(d, legs, 0.05);
    return d;
}

void main(void) {
    
    
    // fetch the playback time
    float time = 0.0;//texelFetch(iChannel0, ivec2(0), 0).a;
    // get the sequence and the time in it
    int seqID = 0;
    float seqTime = 0.0;
    
    //getSequence(time, seqID, seqTime);
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy-iResolution.xy*0.5;
    uv /= iResolution.y;
    
    // get the direction and position
    vec3 dir = vec3(0);
    vec3 from = vec3(0);
    
    getCamera(uv, seqID, seqTime, dir, from);
    
    // initialize skeleton
    initSkel(seqID, seqTime, time);
	
    // extent of a pixel, depends on the resolution
    float fov = 1.0;
    float sinPix = sin(fov/iResolution.y)*2.0;
    // keep best position
    vec3 bestPos = vec3(0);
    float bestPosDist = 999.9;
    // accumulated opacity
    float accAlpha = 1.0;
    // raymarch distance
    float totdist = 0.0;
    /*
    totdist += de(from)*hash13(vec3(fragCoord, iFrame));
    
	for (int steps = Z ; steps < 100 ; steps++) {
		vec3 pos = from + totdist * dir;
        
        // bounding sphere optimisation
        float dist = length(pos) - 4.0;
        if (dist < 1.0) {
            // get actual distance
            dist = de(pos);
            // and cone trace it
            float r = totdist*sinPix;
            float alpha = s(-r, r, dist);
            accAlpha *= alpha;
            // since the legs and arms are very susceptible
            // to overstepping, clamp to a maximum value
            dist = min(0.2, dist);
        }
        
        // keep the closest point to the surface
        if (dist < bestPosDist) {
            bestPos = pos;
            bestPosDist = dist;
        }
        
        // hit a surface, stop and break
		if (dist < 0.001) {
			accAlpha = 0.0;
            break;
		}
		
        // continue forward
        totdist += min(999.9, dist*0.9);
        
	}
    
    fragColor.rgb = vec3(0);
    fragColor.a = 1.0 - accAlpha;
    
    // no need for the normal if the opacity is 0
    if (fragColor.a > 0.001) {
        fragColor.rgb = getNormal(bestPos);
    }
    */
    fragColor = vec4(1.0, 0.0, 0.0, 1.0);
}

#endif