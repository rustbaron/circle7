local lighting = {}
lighting.active = true
lighting.extendLength = 2000
lighting.ambient = 1

-- negative = visible to light; positive = not visible
local function edgeNormal(lx, ly, x1, y1, x2, y2)
  -- cross product
  local cx = y1 - y2
  local cy = -(x1 - x2)
  return math.dot(cx, cy, (x1 + x2) / 2 - lx, (y1 + y2) / 2 - ly) -- the edge normal
end

local function drawShadow(lx, ly, p)
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
      points[count * 2 - pIndex] = x + math.cos(angle) * lighting.extendLength
      points[count * 2 - pIndex + 1] = x + math.sin(angle) * lighting.extendLength
    end

    if #points >= 6 then
      love.graphics.setColor(1, 1, 1, lighting.ambient)
      love.graphics.polygon("fill", unpack(points))
    end
  end
end

function lighting:init()
  self.lights = LinkedList:new("_lightNext", "_lightPrev")
  self.canvas = love.graphics.newCanvas()
  self.lightCanvas = love.graphics.newCanvas()
end

function lighting:draw(canvas, alternate)
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear(self.ambient, self.ambient, self.ambient)

  ammo.world.camera:set()
  for light in self.lights:iterate() do
    if light.alpha > 0 then
      love.graphics.setCanvas(self.lightCanvas)
      love.graphics.clear()
      light:draw()

      love.graphics.setBlendMode("subtract")
      for _, f in ipairs(ammo.world.floor:getFixtures()) do
        drawShadow(light.x, light.y, { f:getShape():getPoints() })
      end

      love.graphics.setBlendMode("alpha")
      love.graphics.setCanvas(self.canvas)
      love.graphics.draw(self.lightCanvas)
    end
  end
  ammo.world.camera:unset()

  love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas(alternate)
  -- love.graphics.setShader(assets.shaders.lightComposite)
  -- assets.shaders.lightComposite:send("lighting", self.canvas)
  love.graphics.draw(self.canvas)
  love.graphics.draw(canvas)
  love.graphics.setShader()
  postfx.swap()
end

function lighting:add(light)
  self.lights:push(light)
end

function lighting:remove(light)
  self.lights:remove(light)
end

function lighting:clear()
  self.lights:clear()
end

return lighting