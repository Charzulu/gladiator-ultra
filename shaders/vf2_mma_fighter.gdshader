shader_type spatial;
render_mode unshaded, cull_disabled;

// Flat shading flag (simulating Model 2 hardware)
uniform bool flat_shading = true;

// Dithering parameters
const mat4 bayer_matrix = mat4(
    vec4( 0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0),
    vec4(12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0),
    vec4( 3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0),
    vec4(15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0)
);

// 6-zone anatomical bruising (0 to 1 intensity)
uniform float bruise_head_intensity : hint_range(0, 1) = 0.0;
uniform float bruise_body_intensity : hint_range(0, 1) = 0.0;
uniform float bruise_left_arm_intensity : hint_range(0, 1) = 0.0;
uniform float bruise_right_arm_intensity : hint_range(0, 1) = 0.0;
uniform float bruise_left_leg_intensity : hint_range(0, 1) = 0.0;
uniform float bruise_right_leg_intensity : hint_range(0, 1) = 0.0;

uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 bruise_color : source_color = vec4(0.4, 0.1, 0.1, 1.0);

varying vec3 var_pos;
varying vec3 var_normal;
varying vec2 var_uv;

void vertex() {
    // Vertex snapping logic for retro look
    vec4 snap_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    snap_pos.xyz = floor(snap_pos.xyz * 120.0) / 120.0; // Snap to low-res grid
    POSITION = snap_pos;

    var_pos = VERTEX;
    var_normal = NORMAL;
    var_uv = UV;
}

void fragment() {
    vec3 normal = var_normal;
    if (flat_shading) {
        // Enforce faceted flat shading
        vec3 p_dx = dFdx(var_pos);
        vec3 p_dy = dFdy(var_pos);
        normal = normalize(cross(p_dx, p_dy));
    }

    // Simulate lighting based on normal
    vec3 light_dir = normalize(vec3(1.0, 1.0, 1.0));
    float diff = max(dot(normal, light_dir), 0.0);

    vec3 final_color = base_color.rgb * (diff * 0.8 + 0.2); // ambient + diffuse

    // Determine basic anatomical zone by UV or local position (placeholder logic)
    // Assuming simple mapping where y position gives height zones
    float bruise_mix = 0.0;

    if (var_pos.y > 1.5) {
        bruise_mix = bruise_head_intensity;
    } else if (var_pos.y > 0.8) {
        bruise_mix = bruise_body_intensity;
    } else {
        bruise_mix = max(bruise_left_leg_intensity, bruise_right_leg_intensity); // Simplification
    }

    final_color = mix(final_color, bruise_color.rgb, bruise_mix);

    // 4x4 Bayer Dithering
    vec2 screen_uv = FRAGCOORD.xy;
    int x = int(mod(screen_uv.x, 4.0));
    int y = int(mod(screen_uv.y, 4.0));
    float threshold = bayer_matrix[x][y];

    // Simple dither on luminance/alpha
    if (length(final_color) < threshold * 1.5) {
        final_color *= 0.8; // Darken to simulate dithering
    }

    ALBEDO = final_color;
}
