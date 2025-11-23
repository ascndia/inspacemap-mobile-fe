#version 300 es
precision mediump float;

// URUTAN UNIFORM (Wajib Sama dengan Dart):
// Index 0-1
uniform vec2 uResolution;
// Index 2-17
uniform mat4 uRotation;
// Index 18
uniform float uFov;
// Index 19
uniform float uFlip; 

uniform sampler2D uTexture;

out vec4 fragColor;

const float PI = 3.14159265359;

void main() {
    vec2 uv = gl_FragCoord.xy / uResolution;
    vec2 ndc = uv * 2.0 - 1.0;
    float aspect = uResolution.x / uResolution.y;

    // LOGIKA MURNI (Punya kamu):
    vec3 ray = normalize(vec3(ndc.x * aspect * uFov, ndc.y * uFov, -1.0));

    // Rotasi 
    vec3 rotatedRay = mat3(uRotation) * ray; 
    
    // Spherical Mapping
    float phi = atan(rotatedRay.z, rotatedRay.x);
    float theta = acos(clamp(rotatedRay.y, -1.0, 1.0));

    // UV Mapping MURNI
    float u = phi / (2.0 * PI) + 0.5;
    float v = theta / PI; 
    
    // Flip V for mobile devices
    v = mix(v, 1.0 - v, uFlip);
    
    fragColor = texture(uTexture, vec2(u, v));
}