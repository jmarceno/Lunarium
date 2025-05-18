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
// Ambient occlusion parameters
uniform float aoIntensity = 0.6;
uniform float aoDistance = 0.2;
// Wall detection: wallMap should contain 1.0 (e.g., in red channel) for wall tiles, 0.0 for non-wall tiles.
uniform Image wallMap;

// Gaussian blur function for normal maps
vec3 blurNormal(ArrayImage normalMap, vec3 texCoord, float blurAmount) {
    if (blurAmount < 0.01) {
        return Texel(normalMap, texCoord).rgb;
    }
    float radius = 0.005 * blurAmount;
    vec2 offsets[9] = vec2[9](
        vec2(-radius, -radius), vec2(0, -radius), vec2(radius, -radius),
        vec2(-radius, 0),       vec2(0, 0),       vec2(radius, 0),
        vec2(-radius, radius),  vec2(0, radius),  vec2(radius, radius)
    );
    float weights[9] = float[9](
        0.0625, 0.125, 0.0625,
        0.125,  0.25,  0.125,
        0.0625, 0.125, 0.0625
    );
    vec3 result = vec3(0.0);
    for(int i = 0; i < 9; i++) {
        vec3 sampleCoord = vec3(texCoord.xy + offsets[i], texCoord.z);
        result += Texel(normalMap, sampleCoord).rgb * weights[i];
    }
    return result;
}

// Check if there is a wall in the cell at the given world integer coordinates (x, y)
// Relies on wallMap where wallMap.r > 0.5 indicates a wall tile.
bool isWall(float x, float y) {
    if (x < 0 || x >= mapDimensions.x || y < 0 || y >= mapDimensions.y) {
        return true; // Treat out-of-bounds as walls for AO at map edges
    }
    return Texel(wallMap, vec2(x + 0.5, y + 0.5) / mapDimensions).r > 0.5;
}

// Calculate ambient occlusion based on proximity to adjacent wall tiles
float calculateAO(float u, float v, vec2 worldPos) {
    float tileX = floor(worldPos.x);
    float tileY = floor(worldPos.y);

    float aoFactor = 1.0; // Start with no occlusion

    // Cardinal wall checks (for edge occlusion)
    bool wallN = isWall(tileX, tileY - 1);
    bool wallE = isWall(tileX + 1, tileY);
    bool wallS = isWall(tileX, tileY + 1);
    bool wallW = isWall(tileX - 1, tileY);

    if (wallN) {
        aoFactor = min(aoFactor, smoothstep(0.0, aoDistance, v));
    }
    if (wallS) {
        aoFactor = min(aoFactor, smoothstep(0.0, aoDistance, 1.0 - v));
    }
    if (wallW) {
        aoFactor = min(aoFactor, smoothstep(0.0, aoDistance, u));
    }
    if (wallE) {
        aoFactor = min(aoFactor, smoothstep(0.0, aoDistance, 1.0 - u));
    }

    // Diagonal wall checks (for external corner occlusion)
    // Occlude NW corner of current tile if wall_diag_NW exists AND N and W tiles are floor
    if (isWall(tileX - 1, tileY - 1) && !wallN && !wallW) {
        float distToCorner = length(vec2(u, v));
        aoFactor = min(aoFactor, smoothstep(0.0, aoDistance, distToCorner));
    }
    // Occlude NE corner of current tile if wall_diag_NE exists AND N and E tiles are floor
    if (isWall(tileX + 1, tileY - 1) && !wallN && !wallE) {
        float distToCorner = length(vec2(1.0 - u, v));
        aoFactor = min(aoFactor, smoothstep(0.0, aoDistance, distToCorner));
    }
    // Occlude SW corner of current tile if wall_diag_SW exists AND S and W tiles are floor
    if (isWall(tileX - 1, tileY + 1) && !wallS && !wallW) {
        float distToCorner = length(vec2(u, 1.0 - v));
        aoFactor = min(aoFactor, smoothstep(0.0, aoDistance, distToCorner));
    }
    // Occlude SE corner of current tile if wall_diag_SE exists AND S and E tiles are floor
    if (isWall(tileX + 1, tileY + 1) && !wallS && !wallE) {
        float distToCorner = length(vec2(1.0 - u, 1.0 - v));
        aoFactor = min(aoFactor, smoothstep(0.0, aoDistance, distToCorner));
    }
    
    return 1.0 - ((1.0 - aoFactor) * aoIntensity);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float step = fov / width;
    float rayAngle = angle-(fov / 2.0f) + (screen_coords.x * step);
    vec2 dir = vec2(cos(rayAngle), sin(rayAngle));
    
    float offsetCorrection = (1*width-(height*2)) / 2;
    float z = (height+cameraOffset+offsetCorrection)/(screen_coords.y-cameraTilt-(height));
    float s = 1.0f - (z/shadeDepth);
    s = clamp(s, 0.0, 1.0);
    float ppx = position.x + dir.x * (z/cos(rayAngle-angle));
    float ppy = position.y + dir.y * (z/cos(rayAngle-angle));
    float ux = floor(ppx);
    float uy = floor(ppy);          
    float u_tex = ppx - ux; // u for texture coord
    float v_tex = ppy - uy; // v for texture coord
    
    vec4 floorData = Texel(map, vec2(ux +0.5, uy+0.5) / mapDimensions);
    float tileId = floorData.r;
    float hintFactor = floorData.g;
    
    vec3 colour;
    if (int(ux) < 0 || int(ux) >= mapDimensions.x || int(uy) < 0 || int(uy) >= mapDimensions.y || tileId < 0) {
        colour = vec3(0.4, 0.4, 0.2) * s;
    } else {
        vec4 diffuseColor = Texel(textures, vec3(u_tex, v_tex, tileId));
        vec3 normal = blurNormal(normalMaps, vec3(u_tex, v_tex, tileId), normalMapBlur);
        normal = normal * 2.0 - 1.0;
        vec3 floorNormal = normalize(vec3(normal.xy * 0.5, 1.0));
        float diffuse = max(0.3, dot(floorNormal, lightDir));
        colour = diffuseColor.rgb * diffuse * s;
    }
    
    float aoFactorToApply = calculateAO(u_tex, v_tex, vec2(ppx, ppy));
    colour *= aoFactorToApply;
    
    colour *= (1.0 - globalDarkness);
    
    if (torchEnabled) {
        float pulse = 0.5 + 0.5 * sin(torchTime);
        float torchFactor = max(0.0, 1.0 - (z / torchRange));
        float intensity = torchIntensity * pulse * torchFactor;
        colour.r += intensity * torchRedTint;
        colour.g += intensity * (1.0 - torchRedTint) * 0.5;
        colour.b += intensity * (1.0 - torchRedTint) * 0.2;
    }
    
    if (gameDebugActive && hintFactor < -0.5) {
        colour = vec3(1.0, 0.0, 1.0);
    } else if (hintFactor > 0.0) {
        vec3 hintColor = vec3(0.9, 0.7, 0.2);
        colour = mix(colour, hintColor, clamp(hintFactor * 0.7, 0.0, 1.0));
    }
    
    return vec4(colour, 1);
}
#endif
]] 