/* vertex shader */
@vs vs
in vec2 pos;
in vec4 color0;

out vec4 color;

void main() {
    gl_Position = vec4(pos, 0.0, 1.0);

    // map coordinates so they from 0 to 1 instead of been from -1 to 1
    gl_Position.xy *= 2;
    gl_Position.xy -= 1;
    color = color0;
}
@end

/* fragment shader */
@fs fs
in vec4 color;
out vec4 frag_color;

void main() {
    frag_color = vec4(color);
}
@end

/* quad shader program */
@program quad vs fs
