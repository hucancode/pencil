#version 330

#define EPSILON 1.0
// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;

// Input uniform values
uniform sampler2D lighting;
uniform sampler2D normal;

// Output fragment color
out vec4 finalColor;

// NOTE: Add here your custom variables
uniform vec2 resolution;

float hatchOffsetY = 5.0;
float lumThreshold01 = 0.9;
float lumThreshold02 = 0.7;
float lumThreshold03 = 0.5;
float lumThreshold04 = 0.3;

vec3 edge() {
    float x = 1.0 / resolution.x;
    float y = 1.0 / resolution.y;

    vec4 horizEdge = vec4(0.0);
    horizEdge -= texture2D(normal, vec2(fragTexCoord.x - x, fragTexCoord.y - y)) * 1.0;
    horizEdge -= texture2D(normal, vec2(fragTexCoord.x - x, fragTexCoord.y)) * 2.0;
    horizEdge -= texture2D(normal, vec2(fragTexCoord.x - x, fragTexCoord.y + y)) * 1.0;
    horizEdge += texture2D(normal, vec2(fragTexCoord.x + x, fragTexCoord.y - y)) * 1.0;
    horizEdge += texture2D(normal, vec2(fragTexCoord.x + x, fragTexCoord.y)) * 2.0;
    horizEdge += texture2D(normal, vec2(fragTexCoord.x + x, fragTexCoord.y + y)) * 1.0;

    vec4 vertEdge = vec4(0.0);
    vertEdge -= texture2D(normal, vec2(fragTexCoord.x - x, fragTexCoord.y - y)) * 1.0;
    vertEdge -= texture2D(normal, vec2(fragTexCoord.x, fragTexCoord.y - y)) * 2.0;
    vertEdge -= texture2D(normal, vec2(fragTexCoord.x + x, fragTexCoord.y - y)) * 1.0;
    vertEdge += texture2D(normal, vec2(fragTexCoord.x - x, fragTexCoord.y + y)) * 1.0;
    vertEdge += texture2D(normal, vec2(fragTexCoord.x, fragTexCoord.y + y)) * 2.0;
    vertEdge += texture2D(normal, vec2(fragTexCoord.x + x, fragTexCoord.y + y)) * 1.0;

    vec3 edge = sqrt((horizEdge.rgb * horizEdge.rgb) + (vertEdge.rgb * vertEdge.rgb));
    float k = clamp(edge.r + edge.g + edge.b, 0.0, 1.0);
    return vec3(k);
}

vec3 hatch() {
    vec3 color = texture2D(lighting, fragTexCoord).rgb;
    float lum = length(color) / sqrt(3.0);
    float ret = 1.0;
    if (lum < lumThreshold01) {
        if (mod(gl_FragCoord.x + gl_FragCoord.y, 10.0) < EPSILON) ret = 0.0;
    }

    if (lum < lumThreshold02) {
        if (mod(gl_FragCoord.x - gl_FragCoord.y, 10.0) < EPSILON) ret = 0.0;
    }

    if (lum < lumThreshold03) {
        if (mod(gl_FragCoord.x + gl_FragCoord.y - hatchOffsetY, 10.0) < EPSILON) ret = 0.0;
    }

    if (lum < lumThreshold04) {
        if (mod(gl_FragCoord.x - gl_FragCoord.y - hatchOffsetY, 10.0) < EPSILON) ret = 0.0;
    }
    return vec3(ret);
}

void main() {
    vec3 color = vec3(0.0);
    color = texture2D(lighting, fragTexCoord).rgb;
    color *= 1.0 - edge();
    color += 0.15;
    color *= hatch();
    float alpha = texture2D(lighting, fragTexCoord).a;
    finalColor = vec4(color, alpha);
}
