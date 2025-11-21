#version 460 core

precision highp float;

uniform vec2 uResolution;
uniform sampler2D uTexture;
uniform mat4 uRotation;
uniform float uFov;

out vec4 fragColor;

const float PI = 3.14159265359;

void main() {
    vec2 pos = gl_FragCoord.xy;
    
    // Normalize coordinates
    vec2 uv = (pos / uResolution) * 2.0 - 1.0;
    
    // Aspect Ratio Correction
    float aspect = uResolution.x / uResolution.y;
    
    // Ray Casting
    // Z is forward (-1.0)
    vec3 ray = normalize(vec3(uv.x * aspect * uFov, -uv.y * uFov, -1.0));
    
    // Apply Rotation
    // Casting to mat3 removes translation (w) components, ensuring pure rotation
    vec3 rotatedRay = mat3(uRotation) * ray;
    
    // Cartesian -> Spherical
    float phi = atan(rotatedRay.z, rotatedRay.x); 
    float theta = acos(rotatedRay.y);             
    
    // Map to UV
    vec2 texCoord = vec2(
        (phi + PI) / (2.0 * PI),
        theta / PI
    );
    
    fragColor = texture(uTexture, texCoord);
}