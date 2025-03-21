@vs vs
// layout(binding=0) uniform vs_params {
//     mat4 mvp;
// };

in vec2 pos;
in vec4 color0;

out vec4 color;

void main() {
    // gl_Position = mvp * vec4(pos, 1.0);
    gl_Position = vec4(pos, 0.0, 1.0);

    // map coordinates so they from 0 to 1 instead of been from -1 to 1
    gl_Position.xy *= 2;
    gl_Position.xy -= 1;
    color = color0;
}
@end

/* quad fragment shader */
@fs fs
// layout(binding=0) uniform texture2D tex;
// layout(binding=0) uniform sampler smp;

in vec4 color;
out vec4 frag_color;

void main() {
    // TODO: investigate better fixel shader https://www.shadertoy.com/view/MlB3D3

    // vec4 texColor = texture(sampler2D(tex, smp), uv) * color;
    // fragColor = vec4(1.0);
    frag_color = vec4(color);
}

@end

/* quad shader program */
@program quad vs fs

