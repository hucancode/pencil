#version 100

precision mediump float;

in vec3 fragNormal;

void main()
{
    vec3 normal = normalize(fragNormal);
    gl_FragColor  = vec4(normal, 1.0);
}
