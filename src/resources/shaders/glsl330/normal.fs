#version 330
in vec3 fragNormal;

out vec4 finalColor;

void main()
{
    vec3 normal = normalize(fragNormal);
    finalColor = vec4(normal, 1.0);
}
