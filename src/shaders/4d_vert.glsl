attribute vec4 aVertexPosition;
attribute vec4 aVertexNormal;
attribute vec4 aVertexColor;

uniform mat4 uMVMatrix;
uniform mat4 uPMatrix;
uniform vec4 uTVector;
uniform vec4 uLightDirection;
uniform vec4 uPVector;

uniform float uR1Float;
uniform float uR2Float;
uniform float uR3Float;
uniform float uR4Float;
uniform float uR5Float;
uniform float uR6Float;

uniform bool uMeshBool;

varying vec4 vColor;

////////////////////////////////////////////////////////////////////////////////

vec4 perspective_proj(vec4 perspective, vec4 position) {
  float x = position[0];
  float y = position[1];
  float z = position[2];
  float w = position[3];
  float p0 = perspective[0];
  float p1 = perspective[1];
  float p2 = perspective[2];
  float p3 = perspective[3];
  float v1 = p3*w;
  float v2 = p0*x;
  float v3 = p1*y;
  float v4 = p2*z;
  float v5 = 1.0 + v1 + v2 + v3 + v4;
  float v6 = 1.0/v5;
  return vec4(v6*x,v6*y,v6*z,v6*w);
}

vec4 rotation(float t1, float t2, float t3, float t4, float t5, float t6, vec4 pos) {
  float x = pos[0];
  float y = pos[1];
  float z = pos[2];
  float w = pos[3];
  float v1 = cos(t1);
  float v2 = sin(t1);
  float v3 = sin(t2);
  float v4 = cos(t2);
  float v5 = sin(t4);
  float v6 = -v3;
  float v7 = cos(t4);
  float v8 = cos(t5);
  float v9 = sin(t3);
  float v10 = sin(t5);
  float v11 = -v4;
  float v12 = cos(t6);
  float v13 = sin(t6);
  float v14 = v5*v6;
  float v15 = v11*v9;
  float v16 = cos(t3);
  float v17 = v1*v7;
  float v18 = v2*v7;
  float v19 = -v10;
  float v20 = v15*v8;
  float v21 = v1*v14;
  float v22 = -v18;
  float v23 = v21 + v22;
  float v24 = v16*x;
  float v25 = v14*v2;
  float v26 = v17 + v25;
  float v27 = v6*v9;
  float v28 = v24*v4;
  float v29 = v1*v20;
  float v30 = v19*v23;
  float v31 = v29 + v30;
  float v32 = v2*v5;
  float v33 = v17*v6;
  float v34 = v32 + v33;
  float v35 = -v13;
  float v36 = v10*v15;
  float v37 = v2*v20;
  float v38 = v19*v26;
  float v39 = v37 + v38;
  float v40 = -v1;
  float v41 = v40*v5;
  float v42 = v18*v6;
  float v43 = v41 + v42;
  float v44 = v10*v11;
  float v45 = v44*v5;
  float v46 = v27*v8;
  float v47 = v45 + v46;
  float v48 = v16*v8;
  return vec4(v1*v28 + (v12*v31 + v34*v35)*w + (v1*v36 + v23*v8)*y + (v13*v31 + v12*v34)*z,v2*v28 + (v12*v39 + v35*v43)*w + (v2*v36 + v26*v8)*y + (v13*v39 + v12*v43)*z,v24*v3 + (v12*v47 + v11*v13*v7)*w + (v10*v27 + v4*v5*v8)*y + (v13*v47 + v12*v4*v7)*z,v12*v48*w + v9*x + v10*v16*y + v13*v48*z);
}

////////////////////////////////////////////////////////////////////////////////

void main(void) {
  // vec4 rotated = rotation(1.0*uRFloat, 2.0*uRFloat, 3.0*uRFloat, 4.0*uRFloat, 5.0*uRFloat, 6.0*uRFloat, aVertexPosition);
  vec4 normal = rotation(uR1Float, uR2Float, uR3Float, uR4Float, uR5Float, uR6Float, aVertexNormal);
  //vec4 normal = aVertexNormal;
  float intensity = max(dot(normal, uLightDirection), 0.0);
  // vec4 translated = rotated + uTVector;
  // vec4 p = perspective_proj(vec4(0.0, 0.0, 0.0, 0.3), translated);
  vec4 translated = aVertexPosition + uTVector;
  
  vec4 rotated = rotation(uR1Float, uR2Float, uR3Float, uR4Float, uR5Float, uR6Float, translated);
  vec4 relativeToCamera = rotated - uPVector;
  vec4 p = perspective_proj(vec4(0.0, 0.0, 0.0, -0.1), relativeToCamera);
  vec4 homogenous3 = vec4(p[0], p[1], p[2], 1.0);

  gl_Position = uPMatrix * uMVMatrix * homogenous3;
  //gl_Position[2] = sqrt(gl_Position[2]*gl_Position[2] - p[3]*p[3]);

  if (uMeshBool) {
    vColor = vec4(1.0, 1.0, 1.0, 0.9);
  } else {
    vColor = 0.1*aVertexColor + 0.9*intensity*aVertexColor;
    vColor[3] = 0.75;
  }
  
  // float r = aVertexColor[0];
  // float g = aVertexColor[1];
  // float b = aVertexColor[2];
  // float a = aVertexColor[3];
  // vColor = vec4(intensity*r, intensity*g, intensity*b, 0.25*a + 0.75*a*intensity);
  // vColor = vec4(0.05*r+0.95*r*intensity, 0.05*g+0.95*g*intensity, 0.05*b+0.95*b*intensity, 0.75);
}
