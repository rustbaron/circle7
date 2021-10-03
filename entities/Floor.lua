Floor = class("Floor", PhysicalEntity)

function Floor:initialize(width, height, tileData, collisionData)
  PhysicalEntity.initialize(self, 0, 0, "static")
  self.layer = 3
  self.width = width
  self.height = height
  self.map = Tilemap:new(assets.images.tileset, TILE_SIZE, TILE_SIZE, width, height)

  for y = 0, #tileData - 1 do
    for x = 0, #tileData[y + 1] - 1 do
      self.map:set(x, y, tileData[y + 1][x + 1] + 1)
    end
  end

  self.collisionData = collisionData
  self.timeElapsed = 0
end

function Floor:added()
  self:setupBody()

  if self.collisionData then
    for _, rect in ipairs(self.collisionData) do
      local fix = self:addShape(
        love.physics.newRectangleShape(rect.x + rect.width / 2, rect.y + rect.height / 2, rect.width, rect.height)
      )
      fix:setCategory(16)
    end

    self.collisionData = nil
  end
end

function Floor:update(dt)
  PhysicalEntity.update(self, dt)
  self.timeElapsed = self.timeElapsed + dt
end

function Floor:draw()
  assets.shaders.glitch:send("intensity", 1)
  love.graphics.setShader(assets.shaders.glitch)
  love.graphics.setColor(0, 0, 0)
  self.map:draw(self.x, self.y)
  love.graphics.setShader()
end