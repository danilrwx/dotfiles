#version 300 es
// Night light: the screen warmed to about 4000 K, blue cut most and green some, as a gamma ramp would; set as
// Hyprland's screen shader by the quick settings' Night Light (config/quickshell), unset to turn it off
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 c = texture(tex, v_texcoord);
    fragColor = vec4(c.r, c.g * 0.82, c.b * 0.58, c.a);
}
