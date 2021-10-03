Lighting = class("Lighting", Entity)

function Lighting:initialize()
  Entity.initialize(self)
  self.layer = 4
  self.canvas = love.graphics.newCanvas(love.graphics.width, love.graphics.height)
  self.lightCanvas = love.graphics.newCanvas(love.graphics.width, love.graphics.height)
  self.lights = LinkedList:new("_lightNext", "_lightPrev")
  self.ambient = 0.15
  self.extendLength = 35000
end

function Lighting:draw()
  self.world.camera:unset()
  self.canvas:renderTo(function() 
    love.graphics.clear(self.ambient, self.ambient, self.ambient)
  end)

  local fixtureShapes = {}
  for _, fixt in ipairs(self.world.floor:getFixtures()) do
    fixtureShapes[#fixtureShapes+1] = { fixt:getShape():getPoints() }
  end

  for light in self.lights:iterate() do
    if light.alpha > 0 then
      self.world.camera:set()
      love.graphics.setCanvas(self.lightCanvas)
      love.graphics.clear()
      -- love.graphics.setBlendMode("add")
      love.graphics.setBlendMode("lighten", "premultiplied")
      light:draw()
      love.graphics.setBlendMode("subtract")
      for _, points in ipairs(fixtureShapes) do
        self:drawShadow(light, points)
      end
      love.graphics.setBlendMode("alpha")
      self.world.camera:unset()
      love.graphics.setCanvas(self.canvas)
      love.graphics.draw(self.lightCanvas)
    end
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas(postfx.alternate)
  love.graphics.draw(postfx.canvas, 0, 0)
  love.graphics.setBlendMode("multiply", "premultiplied")
  love.graphics.draw(self.canvas)
  love.graphics.setBlendMode("alpha")
  postfx.swap()
  self.world.camera:set()
end

function Lighting:add(light)
  self.lights:push(light)
end

function Lighting:remove(light)
  self.lights:remove(light)
end

local function edgeNormal(lx, ly, x1, y1, x2, y2)
  -- cross product
  local cx = y1 - y2
  local cy = -(x1 - x2)
  return math.dot(cx, cy, (x1 + x2) / 2 - lx, (y1 + y2) / 2 - ly) -- the edge normal
end

function Lighting:drawShadow(light, p)
  local lx, ly = light.x, light.y
  local prevNormal = edgeNormal(lx, ly, p[#p - 1], p[#p], p[1], p[2])
  local points = {}
  local start, stop
  local direction = 1

  for i = 1, #p, 2 do
    local normal = edgeNormal(lx, ly, p[i], p[i + 1], p[i + 2] or p[1], p[i + 3] or p[2])
    if normal < 0 and prevNormal >= 0 then
      -- was visible, now isn't - start of a shadow
      start = i
    elseif normal >= 0 and prevNormal < 0 then
      -- wasn't visible now is - end of shadow
      stop = i
      if not start then direction = -1 end
    end
    if start and stop then break end
    prevNormal = normal
  end

  if start and stop then
    local count = math.abs(stop - start) + 2
    for i = start, stop, 2 * direction do
      local x, y = p[i], p[i + 1]
      local angle = math.angle(lx, ly, x, y)
      local pIndex = math.abs(i - start) + 1
      points[pIndex] = x
      points[pIndex + 1] = y
      points[count * 2 - pIndex] = x + math.cos(angle) * self.extendLength
      points[count * 2 - pIndex + 1] = x + math.sin(angle) * self.extendLength
    end

    if #points >= 6 then
      love.graphics.setColor(1, 1, 1)
      love.graphics.polygon("fill", unpack(points))
    end
  end
end