extern float time;
extern float range = 0.05;
extern float noiseIntensity = 0.3;
extern float noiseQuality = 100;
extern Image map;

float rand(vec2 co)
{
  return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

float verticalBar(float pos, float uvY, float offset, float intensity)
{
  float edge0 = (pos - range * intensity);
  float edge1 = (pos + range * intensity);

  float x = smoothstep(edge0, pos, uvY) * offset;
  x -= smoothstep(pos, edge1, uvY) * offset;
  return x;
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
  vec4 intensityVec = Texel(map, tc);
  float intensity = (intensityVec.r + intensityVec.g + intensityVec.b) / 3 * intensityVec.a;
  vec2 uv = vec2(tc.x, tc.y);

  for (float i = 0.0; i < 0.71; i += 0.1313)
  {
    float d = mod((time * i), 1.7);
    float o = sin(1.0 - tan(time * 0.24 * i));
    o *= intensity;
    uv.x += verticalBar(d, uv.y, o, intensity);
  }
  float uvY = uv.y;
  uvY *= noiseQuality;
  uvY = float(int(uvY)) * (1.0 / noiseQuality);
  float noise = rand(vec2(time * 0.00001, uvY));
  uv.x += noise * noiseIntensity * intensity / 100.0;

  vec2 offsetR = vec2(0.0005 * sin(time), 0.0) * intensity;
  vec2 offsetG = vec2(0.0006 * (cos(time * 0.97)), 0.0) * intensity;

  float r = Texel(tex, uv + offsetR).r;
  float g = Texel(tex, uv + offsetG).g;
  float b = Texel(tex, uv).b;

  return vec4(r, g, b, Texel(tex, uv).a);
  // return intensityVec;
  // return vec4(1,1,1,1);
}