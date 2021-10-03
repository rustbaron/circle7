Light = class("Light", Entity)

Light.static.circImages = {}

function Light.static.createCircularImage(radius, inner, intensity)
  inner = inner or 0
  intensity = intensity or 1

  if Light.circImages[radius*intensity] then
    return Light.circImages[radius*intensity]
  end

  local data = love.image.newImageData(radius * 2, radius * 2)

  data:mapPixel(function(x, y)
    local dist = math.dist(radius, radius, x, y)
    return 1, 1, 1, ease.circIn((dist <= radius and math.min(1, math.scale(dist, inner, radius, 1 * intensity, 0)) or 0))
  end)
  
  local im = love.graphics.newImage(data)
  Light.circImages[radius*inner*intensity] = im
  return im
end

function Light.static.createRectImage(width, height, innerWidth, intensity)
  local data = love.image.newImageData(width, height)
  innerWidth = innerWidth or 0
  intensity = intensity or 1

  data:mapPixel(function(x, y)
    local dist = math.dist(x, height / 2, x, y)
    return 1, 1, 1, ease.circIn(math.min(1, math.scale(dist, innerWidth, height / 2, 1 * intensity, 0)))
  end)

  return love.graphics.newImage(data)
end

function Light.static.fromData(light)
  local img = Light.createCircularImage(light.values.radius, light.values.innerRadius or 0, light.values.intensity)
  local l = Light:new(img, light.x, light.y, light.values.radius, light.values.flicker)
  local r, g, b, a = levelColorToRGBA(light.values.color)
  l.color = {r, g, b}
  l.alpha = a

  return l
end

function Light:initialize(img, x, y, radius, flicker)
  Entity.initialize(self, x, y)
  self.visible = false
  self.image = img
  self.radius = radius
  self.angle = 0
  self.color = {1, 1, 1}
  self.alpha = 1
  self.flicker = flicker or 0.1
end

function Light:added()
  self.world.lighting:add(self)
end

function Light:removed()
  self.world.lighting:remove(self)
end

function Light:draw()
  local alpha = self.alpha - self.alpha * self.flicker + self.flicker * math.random()
  love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1)--alpha)
  self:drawImage()
  -- love.graphics.draw(self.image, self.x - self.radius, self.y - self.radius)
  love.graphics.setColor(1, 1, 1)
end