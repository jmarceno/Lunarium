return [[
#ifdef PIXEL
uniform float width;
uniform float height;
uniform vec2 position;
uniform ArrayImage textures;
uniform ArrayImage normalMaps;
uniform Image map;
uniform ivec2 mapDimensions;
uniform float fov;
uniform float angle;
uniform float cameraOffset;
uniform float cameraTilt;
uniform float shadeDepth;
uniform float torchTime;
uniform float torchIntensity;
uniform float torchRange;
uniform float torchRedTint;
uniform float globalDarkness;
uniform bool torchEnabled;
uniform float normalMapBlur;
uniform vec3 lightDir;
uniform bool gameDebugActive;
// Added ambient occlusion parameters
uniform float aoIntensity = 0.7;
uniform float aoDistance = 0.2;

// Ceiling-specific darkness multiplier to differentiate from floor
float ceilingDarknessMultiplier = 0.7;

// Noise function for subtle ceiling texture variations - based on improved Perlin noise
vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Cubic Hermite interpolation
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    // Bilinear interpolation between hash values
    return mix(
        mix(dot(hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
            dot(hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
        mix(dot(hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
            dot(hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
        u.y
    ) * 0.5 + 0.5; // Normalize to 0-1 range
}

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

// Calculate ambient occlusion based on proximity to walls
float calculateAO(float u, float v) {
    // Distance from edges/walls (closest to u=0,1 or v=0,1 is darkest)
    // Calculate how close we are to each wall
    float distFromWallU = min(u, 1.0 - u);
    float distFromWallV = min(v, 1.0 - v);
    
    // Use the closest distance to any wall
    float distFromWall = min(distFromWallU, distFromWallV);
    
    // Smooth transition from dark to light
    float aoFactor = smoothstep(0.0, aoDistance, distFromWall);
    
    // Scale by intensity and invert (1.0 = no darkening, 0.0 = full darkening)
    return 1.0 - ((1.0 - aoFactor) * aoIntensity);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float step = fov / width;
    float rayAngle = angle-(fov / 2.0f) + (screen_coords.x * step);
    vec2 dir = vec2(cos(rayAngle), sin(rayAngle));
    
    float offsetCorrection = (1*width-(height*2)) / 2;
    float z = -1.0*(height+cameraOffset+offsetCorrection)/(screen_coords.y-cameraTilt-(height));
    
    // Fixed shading calculation to match floor shader approach but adapted for ceiling
    float distanceFromCamera = abs(z); // Use absolute distance
    float s = 1.0f - (distanceFromCamera/shadeDepth);
    s = clamp(s, 0.0, 1.0); // Allow complete darkness at max distance
    
    float ppx = position.x + dir.x * (z/cos(rayAngle-angle));
    float ppy = position.y + dir.y * (z/cos(rayAngle-angle));
    float ux = floor(ppx);
    float uy = floor(ppy);          
    float u = ppx - ux;
    float v = ppy - uy;
    
    // Get ceiling data - now using vec4 to fetch additional data
    vec4 ceilingData = Texel(map, vec2(ux +0.5, uy+0.5) / mapDimensions);
    float tileId = ceilingData.r;
    float hintFactor = ceilingData.g; // For future ceiling traps if needed
    
    vec3 colour;
    if (int(ux) < 0 || int(ux) >= mapDimensions.x || int(uy) < 0 || int(uy) >= mapDimensions.y || tileId < 0) {
        // Darker default color for ceiling out of bounds
        colour = vec3(0.15, 0.15, 0.35) * s;
    } else {
        // Get diffuse color from texture
        vec4 diffuseColor = Texel(textures, vec3(u, v, tileId));
        
        // Get normal from normal map with Gaussian blur applied
        vec3 normal = blurNormal(normalMaps, vec3(u, v, tileId), normalMapBlur);
        
        // Transform normal from [0,1] to [-1,1] range
        normal = normal * 2.0 - 1.0;
        
        // Ceiling normal is down by default, but we can perturb it with the normal map
        // Blend between down vector and perturbed normal based on normal map intensity
        vec3 ceilingNormal = normalize(vec3(normal.xy * 0.5, -1.0));
        
        // Calculate diffuse lighting - slightly reduced for ceiling
        float diffuse = max(0.25, dot(ceilingNormal, lightDir));
        
        // Apply lighting and distance shading
        colour = diffuseColor.rgb * diffuse * s;
        
        // Apply ceiling-specific darkness
        colour *= ceilingDarknessMultiplier;
        
        // Apply ambient occlusion
        float aoFactor = calculateAO(u, v);
        colour *= aoFactor;
        
        // Apply subtle noise pattern to ceiling texture
        // Scale noise by world position for consistent pattern size
        float noiseValue = noise(vec2(ppx * 0.5, ppy * 0.5));
        
        // Adjust noise intensity based on distance (more visible up close)
        float noiseIntensity = 0.08 * (1.0 - min(distanceFromCamera / (shadeDepth * 0.5), 1.0));
        
        // Apply the noise as a subtle darkening/lightening effect
        colour *= 1.0 + (noiseValue - 0.5) * noiseIntensity;
        
        // Add subtle dust spots occasionally
        float dustSpot = noise(vec2(ppx * 2.0, ppy * 2.0));
        if (dustSpot > 0.85) {
            // Only apply dust spots to ~15% of ceiling
            float dustIntensity = (dustSpot - 0.85) * 0.5; // Scale to 0-0.075 range
            // Dust appears as subtle darkening
            colour *= 1.0 - dustIntensity;
        }
        
        // Slightly shift to cooler tones for ceiling
        colour.r *= 0.9; // Reduce red
        colour.b *= 1.1; // Increase blue
    }
    
    // Apply global darkness
    colour *= (1.0 - globalDarkness);
    
    // Apply torch effect if enabled
    if (torchEnabled) {
        // Pulsating effect based on time
        float pulse = 0.5 + 0.5 * sin(torchTime);
        
        // Distance-based torch light (stronger near camera)
        float torchFactor = max(0.0, 1.0 - (distanceFromCamera / torchRange));
        
        // Combine pulse with distance for torch intensity
        float intensity = torchIntensity * pulse * torchFactor;
        
        // Apply red-tinted torch light
        colour.r += intensity * torchRedTint;
        colour.g += intensity * (1.0 - torchRedTint) * 0.5;
        colour.b += intensity * (1.0 - torchRedTint) * 0.2;
    }
    
    // Add a subtle vignette to the ceiling to enhance depth perception
    float distanceFromCenter = length(vec2(u - 0.5, v - 0.5));
    float vignette = 1.0 - distanceFromCenter * 0.3;
    colour *= vignette;
    
    // Debug mode for ceiling traps (if we implement them in the future)
    if (gameDebugActive && hintFactor < -0.5) {
        colour = vec3(1.0, 0.0, 1.0); // Magenta for debug
    }
    // Apply hint factor for future ceiling trap highlighting
    else if (hintFactor > 0.0) {
        // Add a subtle hint
        colour += hintFactor * vec3(0.2, 0.2, 0.05);
    }
    
    return vec4(colour, 1);
}
#endif
]] 