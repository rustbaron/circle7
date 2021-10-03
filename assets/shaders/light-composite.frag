extern Image lighting;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
  vec4 lightingColor = Texel(lighting, tc);
  vec4 texColor = Texel(tex, tc);
  float alpha = 1.0 - (lightingColor.r + lightingColor.g + lightingColor.b) / 3;
  return vec4(texColor.r, texColor.g, texColor.b, alpha) * color;
}