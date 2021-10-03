
//based on https://www.shadertoy.com/view/Ms3XWH converted by Exeldro  v 1.0
//updated by Charles 'Surn' Fettinger for obs-shaderfilter 9/2020
extern float intensity = 1;
extern float range = 0.05;
extern float noiseQuality = 500.0;
extern float noiseIntensity = 0.2;
extern float offsetIntensity = 0.01;
extern float colorOffsetIntensity = 1.3;
extern float lumaMin = 0.01;
extern float lumaMinSmooth = 0.04;
extern float Alpha_Percentage = 100; //<Range(0.0,100.0)>
extern bool Apply_To_Image;
extern bool Replace_Image_Color;
extern vec4 Color_To_Replace;
extern bool Apply_To_Specific_Color;
extern float elapsed_time;

float rand(vec2 co)
{
    return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

float verticalBar(float pos, float uvY, float offset)
{
    float edge0 = (pos - range * intensity);
    float edge1 = (pos + range * intensity);

    float x = smoothstep(edge0, pos, uvY) * offset * intensity;
    x -= smoothstep(pos, edge1, uvY) * offset * intensity;
    return x;
}

vec4 lerp(vec4 a, vec4 b, float t)
{
    return vec4(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    vec2 uv = tc;
    for (float i = 0.0; i < 0.71; i += 0.1313)
    {
        float d = mod((elapsed_time * i), 1.7);
        float o = sin(1.0 - tan(elapsed_time * 0.24 * i));
        o *= offsetIntensity;
        uv.x += verticalBar(d, uv.y, o);
    }
    float uvY = uv.y;
    uvY *= noiseQuality;
    uvY = float(int(uvY)) * (1.0 / noiseQuality);
    float noise = rand(vec2(elapsed_time * 0.00001, uvY));
    uv.x += noise * noiseIntensity * intensity / 100.0;

    vec2 offsetR = vec2(0.0005 * sin(elapsed_time), 0.0) * colorOffsetIntensity * intensity;
    vec2 offsetG = vec2(0.0006 * (cos(elapsed_time * 0.97)), 0.0) * colorOffsetIntensity * intensity;

    float r = Texel(tex, uv + offsetR).r * color.r;
    float g = Texel(tex, uv + offsetG).g * color.g;
    float b = Texel(tex, uv).b * color.b;
    vec4 rgba = vec4(r, g, b, Texel(tex, uv).a);

    vec4 col = Texel(tex, tc);
    vec4 originalColor = Texel(tex, tc);
    // if (Apply_To_Image)
    // {
    //     vec4 luma = dot(col, vec4(0.30, 0.59, 0.11, 1.0));
    //     if (Replace_Image_Color)
    //         col = luma;
    //     rgba = lerp(originalColor, rgba * col, clamp(Alpha_Percentage * .01, 0, 1.0));
		
    // }
    if (Apply_To_Specific_Color)
    {
        col = (distance(col.rgb, Color_To_Replace.rgb) <= 0.075) ? rgba : col;
        rgba = lerp(originalColor, col, clamp(Alpha_Percentage * .01, 0, 1.0));
    }

    return rgba;
    // return vec4(r, g, b, Texel(tex, uv).a);
}
