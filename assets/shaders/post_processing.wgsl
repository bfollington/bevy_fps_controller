#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput

@group(0) @binding(0) var screen_texture: texture_2d<f32>;
@group(0) @binding(1) var texture_sampler: sampler;
struct PostProcessSettings {
    intensity: f32,
#ifdef SIXTEEN_BYTE_ALIGNMENT
    _webgl2_padding: vec3<f32>
#endif
}
@group(0) @binding(2) var<uniform> settings: PostProcessSettings;

@fragment
fn fragment(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    let offset_strength = settings.intensity;

    let uv = in.uv;

    // Sample the texture three times with offsets
    let color_r = textureSample(screen_texture, texture_sampler, uv + vec2<f32>(offset_strength, -offset_strength)).r;
    let color_g = textureSample(screen_texture, texture_sampler, uv + vec2<f32>(-offset_strength, 0.0)).g;
    let color_b = textureSample(screen_texture, texture_sampler, uv + vec2<f32>(0.0, offset_strength)).b;

    // Combine the color channels
    let final_color = vec3<f32>(color_r, color_g, color_b);

    // Ensure we're not exceeding the original brightness
    let original = textureSample(screen_texture, texture_sampler, uv).rgb;
    let max_component = max(max(original.r, original.g), original.b);

    // Normalize the final color to match the original brightness
    let normalized_color = final_color * (max_component / max(max(final_color.r, final_color.g), final_color.b));

    return vec4<f32>(normalized_color, 1.0);
}
