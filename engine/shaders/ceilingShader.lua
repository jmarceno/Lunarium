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

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float step = fov / width;
    float rayAngle = angle-(fov / 2.0f) + (screen_coords.x * step);
    vec2 dir = vec2(cos(rayAngle), sin(rayAngle));
    
    float offsetCorrection = (1*width-(height*2)) / 2;
    float z = -1.0*(height+cameraOffset+offsetCorrection)/(screen_coords.y-cameraTilt-(height));
    float s = 1.0f - (-z/shadeDepth);
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
        colour = vec3(0.2, 0.2, 0.4) * s; // Default color for out of bounds
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
        
        // Calculate diffuse lighting
        float diffuse = max(0.3, dot(ceilingNormal, lightDir));
        
        // Apply lighting and distance shading
        colour = diffuseColor.rgb * diffuse * s;
    }
    
    // Apply global darkness
    colour *= (1.0 - globalDarkness);
    
    // Apply torch effect if enabled
    if (torchEnabled) {
        // Pulsating effect based on time
        float pulse = 0.5 + 0.5 * sin(torchTime);
        
        // Distance-based torch light (stronger near camera)
        float torchFactor = max(0.0, 1.0 - (-z / torchRange));
        
        // Combine pulse with distance for torch intensity
        float intensity = torchIntensity * pulse * torchFactor;
        
        // Apply red-tinted torch light
        colour.r += intensity * torchRedTint;
        colour.g += intensity * (1.0 - torchRedTint) * 0.5;
        colour.b += intensity * (1.0 - torchRedTint) * 0.2;
    }
    
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