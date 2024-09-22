#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput

@group(0) @binding(0) var screen_texture: texture_2d<f32>;
@group(0) @binding(1) var texture_sampler: sampler;

struct PostProcessSettings {
    pixel_size: f32,
    edge_threshold: f32,
    color_depth: f32,
    effect_strength: f32,
}
@group(0) @binding(2) var<uniform> settings: PostProcessSettings;

fn pixelate(uv: vec2<f32>) -> vec2<f32> {
    let pixel_count = max(settings.pixel_size, 1.0);
    return floor(uv * pixel_count) / pixel_count;
}

fn detect_edges(uv: vec2<f32>) -> f32 {
    let offset = 1.0 / vec2<f32>(textureDimensions(screen_texture));

    let c00 = textureSample(screen_texture, texture_sampler, uv + vec2(-1.0, -1.0) * offset).rgb;
    let c10 = textureSample(screen_texture, texture_sampler, uv + vec2( 0.0, -1.0) * offset).rgb;
    let c20 = textureSample(screen_texture, texture_sampler, uv + vec2( 1.0, -1.0) * offset).rgb;
    let c01 = textureSample(screen_texture, texture_sampler, uv + vec2(-1.0,  0.0) * offset).rgb;
    let c21 = textureSample(screen_texture, texture_sampler, uv + vec2( 1.0,  0.0) * offset).rgb;
    let c02 = textureSample(screen_texture, texture_sampler, uv + vec2(-1.0,  1.0) * offset).rgb;
    let c12 = textureSample(screen_texture, texture_sampler, uv + vec2( 0.0,  1.0) * offset).rgb;
    let c22 = textureSample(screen_texture, texture_sampler, uv + vec2( 1.0,  1.0) * offset).rgb;

    let horizontal = -c00 - 2.0*c10 - c20 + c02 + 2.0*c12 + c22;
    let vertical = -c00 - 2.0*c01 - c02 + c20 + 2.0*c21 + c22;

    return length(horizontal) + length(vertical);
}

fn quantize_and_dither(color: vec3<f32>, uv: vec2<f32>) -> vec3<f32> {
    let color_depth = max(settings.color_depth, 2.0);

    // Simple dithering pattern using fract
    let x = fract(uv.x * f32(textureDimensions(screen_texture).x));
    let y = fract(uv.y * f32(textureDimensions(screen_texture).y));
    let dither_value = (fract(x * 0.375 + y * 0.75 + 0.8) * 2.0 - 1.0) / color_depth;

    return floor((color + vec3(dither_value)) * color_depth) / (color_depth - 1.0);
}

@fragment
fn fragment(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    let original_color = textureSample(screen_texture, texture_sampler, in.uv).rgb;
    let pixelated_uv = pixelate(in.uv);
    var color = textureSample(screen_texture, texture_sampler, pixelated_uv).rgb;

    let edge = detect_edges(pixelated_uv);
    color = mix(color, vec3(0.0), smoothstep(0.0, settings.edge_threshold, edge) * 0.5);

    color = quantize_and_dither(color, in.uv);

    // Blend the processed color with the original based on effect_strength
    color = mix(original_color, color, settings.effect_strength);

    return vec4(color, 1.0);
}
