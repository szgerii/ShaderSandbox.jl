#version 330 core

out vec4 outColor;

uniform float time;
uniform ivec2 resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / resolution;

    vec3 col = 0.5 + 0.5 * cos(time + uv.xyx + vec3(0, 2, 4));

    outColor = vec4(col, 1.0);
}
