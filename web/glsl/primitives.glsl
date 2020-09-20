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
uniform vec3 bodyroot;
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
    //p.y += 0.5;
    p -= bodyroot;

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
    vec3 inNeck = inUpperBodyNoFlip - vec3(0.0, 0.68, -0.1);
    inNeck = rotateLimb(inNeck, 2);
    float neck = getNeck(inNeck);
    vec3 inHead = inNeck - vec3(0.0, 0.24, 0.07);
    inHead = rotateLimb(inHead, 3);
    
    float head = getHead(inHead);
    // do the arms
    vec3 inShoulder = inUpperBody - vec3(0.4, 0.48, -0.12);
    inShoulder = rotateArm(inShoulder, 4+upperOffset);
    float shoulder = getUpperArm(inShoulder);
    vec3 inElbow = inShoulder - vec3(0.79, 0.0, 0.0);
    inElbow = rotateArm(inElbow, 5+upperOffset);
    float elbow = getForearm(inElbow);
    vec3 inHand = inElbow - vec3(0.56, 0.0, 0.0);
    inHand = rotateArm(inHand, 6+upperOffset);
    float hand = getHand(inHand);
    
    // do the legs
    vec3 inHip = inLowerBody - vec3(0.25, -0.79, 0.0);
    inHip = rotateLimb(inHip, 10+lowerOffset);
    float hip = getUpperLeg(inHip);
    vec3 inKnee = inHip - vec3(0.0, -1.01, 0.0);
    inKnee = rotateLimb(inKnee, 11+lowerOffset);
    float knee = getLowerLeg(inKnee);
    vec3 inFoot = inKnee - vec3(0.0, -1.06, -0.08);
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

vec2 opU( vec2 d1, vec2 d2 ) {
	return (d1.x<d2.x) ? d1 : d2;
}

vec2 map( in vec3 pos ) {
    vec2 res = vec2( 1e10, 0.0 );
    
    {
      res = opU( res, vec2( sdSphere(    pos-vec3(-2.0,0.25, 0.0), 0.25 ), 26.9 ) );
    }
    /*
    {
	res = opU( res, vec2( sdPyramid(    pos-vec3(-1.0,-0.6,-3.0), 1.0 ), 13.56 ) );
	res = opU( res, vec2( sdOctahedron( pos-vec3(-1.0,0.15,-2.0), 0.35 ), 23.56 ) );
    res = opU( res, vec2( sdTriPrism(   pos-vec3(-1.0,0.15,-1.0), vec2(0.3,0.05) ),43.5 ) );
    res = opU( res, vec2( sdEllipsoid(  pos-vec3(-1.0,0.25, 0.0), vec3(0.2, 0.25, 0.05) ), 43.17 ) );
	res = opU( res, vec2( sdRhombus(   (pos-vec3(-1.0,0.34, 1.0)).xzy, 0.15, 0.25, 0.04, 0.08 ),17.0 ) );
    }

    {
    res = opU( res, vec2( sdBoundingBox( pos-vec3( 0.0,0.25, 0.0), vec3(0.3,0.25,0.2), 0.025 ), 16.9 ) );
	res = opU( res, vec2( sdTorus(      (pos-vec3( 0.0,0.30, 1.0)).xzy, vec2(0.25,0.05) ), 25.0 ) );
	res = opU( res, vec2( sdCone(        pos-vec3( 0.0,0.45,-1.0), vec2(0.6,0.8),0.45 ), 55.0 ) );
    res = opU( res, vec2( sdCappedCone(  pos-vec3( 0.0,0.25,-2.0), 0.25, 0.25, 0.1 ), 13.67 ) );
    res = opU( res, vec2( sdSolidAngle(  pos-vec3( 0.0,0.00,-3.0), vec2(3,4)/5.0, 0.4 ), 49.13 ) );
    }

    {
	res = opU( res, vec2( sdCappedTorus((pos-vec3( 1.0,0.30, 1.0))*vec3(1,-1,1), vec2(0.866025,-0.5), 0.25, 0.05), 8.5) );
    res = opU( res, vec2( sdBox(         pos-vec3( 1.0,0.25, 0.0), vec3(0.3,0.25,0.1) ), 3.0 ) );
    res = opU( res, vec2( sdCapsule(     pos-vec3( 1.0,0.00,-1.0),vec3(-0.1,0.1,-0.1), vec3(0.2,0.4,0.2), 0.1  ), 31.9 ) );
	res = opU( res, vec2( sdCylinder(    pos-vec3( 1.0,0.25,-2.0), vec2(0.15,0.25) ), 8.0 ) );
    res = opU( res, vec2( sdHexPrism(    pos-vec3( 1.0,0.2,-3.0), vec2(0.2,0.05) ), 18.4 ) );
    }

    {
    res = opU( res, vec2( sdOctogonPrism(pos-vec3( 2.0,0.2,-3.0), 0.2, 0.05), 51.8 ) );
    res = opU( res, vec2( sdCylinder(    pos-vec3( 2.0,0.15,-2.0), vec3(0.1,-0.1,0.0), vec3(-0.2,0.35,0.1), 0.08), 31.2 ) );
	res = opU( res, vec2( sdCappedCone(  pos-vec3( 2.0,0.10,-1.0), vec3(0.1,0.0,0.0), vec3(-0.2,0.40,0.1), 0.15, 0.05), 46.1 ) );
    res = opU( res, vec2( sdRoundCone(   pos-vec3( 2.0,0.15, 0.0), vec3(0.1,0.0,0.0), vec3(-0.1,0.35,0.1), 0.15, 0.05), 51.7 ) );
    res = opU( res, vec2( sdRoundCone(   pos-vec3( 2.0,0.20, 1.0), 0.2, 0.1, 0.3 ), 37.0 ) );
    }
*/
    res = opU(res, vec2(bodydistance(pos), 10.5));
    
    return res;
}

vec2 raycast( in vec3 ro, in vec3 rd ) {
    vec2 res = vec2(-1.0, -1.0);
    float tmax = 20.0;

    //floor
    float tp1 = (0.0-ro.y)/rd.y;
    if( tp1>0.0 ) {
        tmax = min(tmax, tp1);
        res = vec2( tp1, 1.0 );
    }
    
    vec2 bound = iSphere(ro, rd, bodyroot, 3.5); //only raymarch within this sphere
    float t = bound.x; //min
    tmax = min(tmax, bound.y); //max

    if(t>0.0) {
        for( int i=0; i<80 && t<tmax; i++ ) {
            vec2 h = map(ro + rd*t);
            h.x = min(0.15, h.x); //limit stepsize cuz overstepping.
            if(abs(h.x)<(0.001*t)) {
                res = vec2(t,h.y);
                break;
            }
            t += 0.99*h.x;
        }
    }
    return res;
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax ) {
    // bounding volume
    float tp = (0.8-ro.y)/rd.y; if( tp>0.0 ) tmax = min( tmax, tp );
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ ) {
		float h = map( ro + rd*t ).x;
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s*s*(3.0-2.0*s) );
        t += clamp( h, 0.02, 0.10 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 pos ) {
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ).x + e.yyx*map( pos + e.yyx ).x + e.yxy*map( pos + e.yxy ).x + e.xxx*map( pos + e.xxx ).x );
}

float calcAO( in vec3 pos, in vec3 nor ) {
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ ) {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = map( pos + h*nor ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
        if( occ>0.35 ) break;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

float checkersTexture( in vec2 p ) {
    vec2 q = floor(p);
    return mod( q.x+q.y, 2.0 );
}

vec3 render( in vec3 ro, in vec3 rd) {
    // background
    vec3 col = vec3(0.7, 0.7, 0.9) - max(rd.y,0.0)*0.3;
    
    // raycast scene
    vec2 res = raycast(ro,rd);
    float t = res.x;
	float m = res.y; //model number
    if( m>-0.5 ) {
        vec3 pos = ro + t*rd;
        vec3 nor = (m<1.5) ? vec3(0.0,1.0,0.0) : calcNormal( pos );
        vec3 ref = reflect( rd, nor );
        
        // material        
        col = 0.2 + 0.2*sin(2.0*m + vec3(0.0, 1.0, 2.0));
        float ks = 1.0;
        
        if (m<1.5) {
            float f = checkersTexture(pos.xz);
            col = 0.15 + f*vec3(0.05);
            ks = 0.4;
        }

        // lighting
        float occ = calcAO( pos, nor );
		vec3 lin = vec3(0.0);

        // sun
        {
            vec3  lig = normalize( vec3(-0.5, 0.4, -0.6) );
            vec3  hal = normalize( lig-rd );
            float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        	      dif *= calcSoftshadow( pos, lig, 0.02, 2.5 );
			float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0);
                  spe *= dif;
                  spe *= 0.04+0.96*pow(clamp(1.0-dot(hal,lig),0.0,1.0),5.0);
            lin += col*2.20*dif*vec3(1.30,1.00,0.70);
            lin +=     5.00*spe*vec3(1.30,1.00,0.70)*ks;
        }
        // sky
        {
            float dif = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
                  dif *= occ;
            float spe = smoothstep( -0.2, 0.2, ref.y );
                  spe *= dif;
                  spe *= calcSoftshadow( pos, ref, 0.02, 2.5 );
                  spe *= 0.04+0.96*pow(clamp(1.0+dot(nor,rd),0.0,1.0), 5.0 );
            lin += col*0.60*dif*vec3(0.40,0.60,1.15);
            lin +=     2.00*spe*vec3(0.40,0.60,1.30)*ks;
        }
        // back
        {
        	float dif = clamp( dot( nor, normalize(vec3(0.5,0.0,0.6))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
                  dif *= occ;
        	lin += col*0.55*dif*vec3(0.25,0.25,0.25);
        }
        // sss
        {
            float dif = pow(clamp(1.0+dot(nor,rd),0.0,1.0),2.0);
                  dif *= occ;
        	lin += col*0.25*dif*vec3(1.00,1.00,1.00);
        }
        
		col = lin;
        col = mix( col, vec3(0.7,0.7,0.9), 1.0-exp( -0.0001*t*t*t ) );
    }
	return vec3( clamp(col,0.0,1.0) );
}

void main(void) {
    vec2 uv = gl_FragCoord.xy-iResolution.xy*0.5; // Normalized pixel coordinates (from 0 to 1)
    uv /= iResolution.y;

    vec3 lookAt = vec3(bodyroot);
    vec3 ro = vec3(6.0*cos(0.1*iTime), 4.0, 6.0*sin(0.1*iTime));
    //vec3 ro = vec3(6.0, 2.0, 0.0);
    vec3 rd = raydir(uv, ro, lookAt);
    vec3 col = render( ro, rd);
    
    col = pow( col, vec3(0.4545) ); //gamma
    fragColor = vec4( col, 1.0 );
}

#endif