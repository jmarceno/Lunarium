return [[
#ifdef PIXEL
#define MAIN_CANVAS 0

struct RenderData {
    float textureId;
    float wallHeight;
    float u;
    float shade;
    float rayLength;
    float z;
    float hintFactor;
};

uniform Image dataBuffer;
uniform ArrayImage textures;
uniform ArrayImage normalMaps;
uniform float cameraOffset;
uniform float cameraTilt;
uniform float torchTime;
uniform float torchIntensity;
uniform float torchRange;
uniform float torchRedTint;
uniform float globalDarkness;
uniform bool torchEnabled;
uniform float normalMapBlur;
uniform vec3 lightDir;
uniform bool gameDebugActive;

// Gaussian blur function for normal maps
vec3 blurNormal(ArrayImage normalMap, vec3 texCoord, float blurAmount) {
    // Skip blur if amount is very small
    if (blurAmount < 0.01) {
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
        vec3 sampleCoord = vec3(texCoord.xy + offsets[i], texCoord.z);
        result += Texel(normalMap, sampleCoord).rgb * weights[i];
    }
    
    return result;
}

RenderData extractRenderData(float screenU) {
    RenderData result;
    
    vec4 row1 = Texel(dataBuffer, vec2(screenU, 0));
    vec4 row2 = Texel(dataBuffer, vec2(screenU, 1));
    
    result.textureId = row1.r;
    result.wallHeight = row1.g;
    result.u = row1.b;
    result.shade = row1.a;
    result.rayLength = row2.r;
    result.z = row2.g;
    result.hintFactor = row2.b;
    
    return result;
}

void effect() {
    vec2 screen_coords = love_PixelCoord;
    RenderData rd = extractRenderData((screen_coords.x)/love_ScreenSize.x);
    
    float ceilling = (love_ScreenSize.y/2.0) - (rd.wallHeight/2.0) + (cameraOffset / rd.rayLength) + cameraTilt;
    float floor = ceilling + rd.wallHeight;
    float v = (screen_coords.y-ceilling) / rd.wallHeight;
    
    if (screen_coords.y < ceilling || screen_coords.y > floor) {
        // Write a blank pixel and set max depth for areas that aren't walls
        love_Canvases[MAIN_CANVAS] = vec4(0);
        gl_FragDepth = 1;
    } else {
        // Get diffuse color from texture
        vec4 diffuseColor = Texel(textures, vec3(rd.u, v, rd.textureId));
        
        // Get normal from normal map with Gaussian blur applied
        vec3 normal = blurNormal(normalMaps, vec3(rd.u, v, rd.textureId), normalMapBlur);
        
        // Transform normal from [0,1] to [-1,1] range
        normal = normal * 2.0 - 1.0;
        
        // Calculate lighting direction based on side (depends on ray direction)
        vec3 lighting;
        if (rd.textureId > 0.0) {
            // Determine lighting based on wall normal and light direction
            float diffuse = max(0.3, dot(normal, lightDir));
            
            // Apply base shade from distance and side
            lighting = vec3(diffuse * rd.shade);
        } else {
            // Fallback for non-textured walls
            lighting = vec3(rd.shade);
        }
        
        // Apply lighting to color
        vec3 colour = diffuseColor.rgb * lighting;
        
        // Apply global darkness
        colour *= (1.0 - globalDarkness);
        
        // Apply torch effect if enabled
        if (torchEnabled) {
            // Pulsating effect based on time
            float pulse = 0.5 + 0.5 * sin(torchTime);
            
            // Distance-based torch light (stronger near camera)
            float torchFactor = max(0.0, 1.0 - (rd.rayLength / torchRange));
            
            // Combine pulse with distance for torch intensity
            float intensity = torchIntensity * pulse * torchFactor;
            
            // Enhanced torch effect using normal map
            float normalFactor = max(0.0, dot(normal, vec3(0.0, 0.0, 1.0)));
            intensity *= (0.7 + 0.3 * normalFactor);
            
            // Apply red-tinted torch light
            colour.r += intensity * torchRedTint;
            colour.g += intensity * (1.0 - torchRedTint) * 0.5;
            colour.b += intensity * (1.0 - torchRedTint) * 0.2;
        }
        
        // Debug mode for traps/secret walls - if hintFactor is -1.0, show magenta
        if (gameDebugActive && rd.hintFactor < -0.5) {
            colour = vec3(1.0, 0.0, 1.0); // Magenta for debug
        }
        // Apply hint factor for subtle highlighting - only if hintFactor > 0
        else if (rd.hintFactor > 0.0) {
            // Add a subtle hint by brightening and slightly tinting the wall
            colour += rd.hintFactor * vec3(0.2, 0.2, 0.1);
        }
        
        love_Canvases[MAIN_CANVAS] = vec4(colour, diffuseColor.a);
        gl_FragDepth = rd.z;
    }
}
#endif
]] 