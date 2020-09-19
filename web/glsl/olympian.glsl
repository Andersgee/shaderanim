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
uniform vec3 skel[16];
out vec4 fragColor;

// rotate an arm
vec3 rotateArm(vec3 p, int i) {
    vec3 pitchYawRoll = skel[i];
    p.xz *= rot(pitchYawRoll.y);
    p.xy *= rot(pitchYawRoll.x);
    p.yz *= rot(pitchYawRoll.z);
    return p;
}

// rotate a limb
vec3 rotateLimb(vec3 p, int i) {
    vec3 pitchYawRoll = skel[i];
    p.xz *= rot(pitchYawRoll.y);
    p.yz *= rot(pitchYawRoll.x);
    p.xz *= rot(pitchYawRoll.z);
    return p;
}

// main distance function
float bodydistance(vec3 p) {
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
    int upperOffset = int(inUpperBody.x > 0.0)*3.0;
    int lowerOffset = int(inLowerBody.x > 0.0)*3.0;
    inUpperBody = vec3(abs(inUpperBody.x), inUpperBody.yz);
    inLowerBody = vec3(abs(inLowerBody.x), inLowerBody.yz);
    
    float torso = getTorso(inUpperBody);
    float pelvis = getPelvis(inLowerBody);
    
    // do the neck and head
    vec3 inNeck = inUpperBodyNoFlip - vec3(0.0, 0.68, -0.1);
    inNeck = rotateLimb(inNeck, 2.0);
    float neck = getNeck(inNeck);
    vec3 inHead = inNeck - vec3(0.0, 0.24, 0.07);
    inHead = rotateLimb(inHead, 3.0);
    
    float head = getHead(inHead);
    // do the arms
    vec3 inShoulder = inUpperBody - vec3(0.4, 0.48, -0.12);
    inShoulder = rotateArm(inShoulder, 4+upperOffset);
    float shoulder = getUpperArm(inShoulder);
    vec3 inElbow = inShoulder - vec3(0.79, 0.0, 0.0);
    inElbow = rotateArm(inElbow, 5+upperOffset);
    float elbow = getForearm(inElbow);
    vec3 inHand = inElbow - vec3(0.56, 0.0, 0.0);
    inHand = rotateArm(inHand, 6.0+upperOffset);
    float hand = getHand(inHand);
    
    // do the legs
    vec3 inHip = inLowerBody - vec3(0.25, -0.79, 0.0);
    inHip = rotateLimb(inHip, 10.0+lowerOffset);
    float hip = getUpperLeg(inHip);
    vec3 inKnee = inHip - vec3(0.0, -1.01, 0.0);
    inKnee = rotateLimb(inKnee, 11.0+lowerOffset);
    float knee = getLowerLeg(inKnee);
    vec3 inFoot = inKnee - vec3(0.0, -1.06, -0.08);
    inFoot = rotateLimb(inFoot, 12.0+lowerOffset);
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

vec3 getNormal(vec3 p) {
    vec4 n = vec4(0.0);
    for (int i = 0 ; i < 4 ; i++) {
        vec4 s = vec4(p, 0.0);
        s[i] += 0.001;
        n[i] = bodydistance(s.xyz);
    }
    return normalize(n.xyz-n.w);
}

void main() {
    vec2 uv = gl_FragCoord.xy-iResolution.xy*0.5;
    uv /= iResolution.y;
    
    vec3 ro = vec3(5.0*sin(0.5*iTime), 5.0, 5.0*cos(0.5*iTime));
    vec3 lookAt = vec3(0.0);
    vec3 rd = raydir(uv, ro, lookAt);
    
    vec3 p = vec3(0.0);
    float d = 0.0;
    float t = 0.0;

	for (int steps = 0 ; steps < 100 ; steps++) {
		p = ro + t * rd;
        d = bodydistance(p);
		if (d < 0.001) {
            fragColor.rgb = getNormal(p);
            fragColor.a = 1.0;
            break;
		} else if (p.y<-3.0) {
            fragColor.rgb = vec3(0.0);
            fragColor.a = 1.0;
            break;
        }
        t += min(999.9, d*0.9);
	}
}

#endif