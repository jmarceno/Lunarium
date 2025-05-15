return [[
#ifdef VERTEX
attribute float VertexDepth;

varying float v_depth;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    v_depth = VertexDepth;
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
varying float v_depth;
uniform float shadeDepth;
uniform float depth;
uniform float torchTime;
uniform float torchIntensity;
uniform float torchRange;
uniform float torchRedTint;
uniform float globalDarkness;
uniform bool torchEnabled;
uniform vec3 lightDir;
uniform Image normalMap;
uniform bool hasNormalMap;
uniform bool enemyNormalMapBlurEnabled;
uniform float enemyNormalMapBlur;

// Gaussian blur function for normal maps
vec3 blurNormal(Image normalMap, vec2 texCoord, float blurAmount, bool blurEnabled) {
    // Skip blur if amount is very small or blur is disabled
    if (blurAmount < 0.01 || !hasNormalMap || !blurEnabled) {
        return Texel(normalMap, texCoord).rgb;
    }
    
    // Calculate blur radius based on blur amount (0-1)
    float radius = 0.005 * blurAmount;
    
    // Sample points for Gaussian 3x3 kernel
    vec2 offsets[9] = vec2[9](
        vec2(-radius, -radius), vec2(0, -radius), vec2(radius, -radius),
        vec2(-radius, 0),       vec2(0, 0),       vec2(radius, 0),
        vec2(-radius, radius),  vec2(0, radius),  vec2(radius, radius)
    );
    
    // Gaussian weights (normalized)
    float weights[9] = float[9](
        0.0625, 0.125, 0.0625,
        0.125,  0.25,  0.125,
        0.0625, 0.125, 0.0625
    );
    
    // Accumulate blurred result
    vec3 result = vec3(0.0);
    for(int i = 0; i < 9; i++) {
        vec2 sampleCoord = texCoord + offsets[i];
        result += Texel(normalMap, sampleCoord).rgb * weights[i];
    }
    
    return result;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texcolor = Texel(texture, texture_coords);
    if (texcolor.a < 0.1) discard;
    
    float shade = 1.0 - (v_depth / shadeDepth);
    shade = clamp(shade, 0.0, 1.0); // Allow complete darkness at max distance
    
    vec3 normal = vec3(0.0, 0.0, 1.0); // Default forward-facing normal
    
    // If normal map is available, use it with blur applied
    if (hasNormalMap) {
        vec3 normalValue = blurNormal(normalMap, texture_coords, enemyNormalMapBlur, enemyNormalMapBlurEnabled);
        normal = normalValue * 2.0 - 1.0; // Convert from [0,1] to [-1,1]
    }
    
    // Calculate diffuse lighting
    float diffuse = max(0.3, dot(normal, lightDir));
    
    // Apply lighting
    vec3 colour = texcolor.rgb * diffuse * shade * color.rgb;
    
    // Apply global darkness
    colour *= (1.0 - globalDarkness);
    
    // Apply torch effect if enabled
    if (torchEnabled) {
        // Pulsating effect based on time
        float pulse = 0.5 + 0.5 * sin(torchTime);
        
        // Distance-based torch light (stronger near camera)
        float torchFactor = max(0.0, 1.0 - (v_depth / torchRange));
        
        // Combine pulse with distance for torch intensity
        float intensity = torchIntensity * pulse * torchFactor;
        
        // Enhanced torch effect using normal map if available
        if (hasNormalMap) {
            float normalFactor = max(0.0, dot(normal, vec3(0.0, 0.0, 1.0)));
            intensity *= (0.7 + 0.3 * normalFactor);
        }
        
        // Apply red-tinted torch light
        colour.r += intensity * torchRedTint;
        colour.g += intensity * (1.0 - torchRedTint) * 0.5;
        colour.b += intensity * (1.0 - torchRedTint) * 0.2;
    }
    
    gl_FragDepth = depth;
    return vec4(colour, texcolor.a * color.a);
}
#endif
]] 