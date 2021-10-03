EnemyPiece = class("EnemyPiece", PhysicalEntity)
EnemyPiece.WIDTH = 2
EnemyPiece.HEIGHT = 2
EnemyPiece.image = love.graphics.newCanvas(EnemyPiece.WIDTH * 3, EnemyPiece.HEIGHT * 3)
EnemyPiece.image:renderTo(function()
  love.graphics.draw(getRectImage(EnemyPiece.WIDTH, EnemyPiece.HEIGHT), EnemyPiece.WIDTH, EnemyPiece.HEIGHT)
end)
EnemyPiece.CLEANUP_TIME = 2

function EnemyPiece:initialize(x, y, angle, force, color)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.angle = angle
  self.color = color
  self.color[4] = 1
  self.force = force
  self.timerStarted = false
  self.cleanupTimer = 0
  self.dead = false
  self.layer = 8
end

function EnemyPiece:added()
  self:setupBody()
  self:setMass(1)
  self.fixture = self:addShape(love.physics.newRectangleShape(self.WIDTH, self.HEIGHT))
  self.fixture:setCategory(10)
  self.fixture:setMask(1,2,3,4,5,6,7,8,9,11,12,13,14,15) -- all but floor and other pieces
  self:applyLinearImpulse(math.cos(self.angle) * self.force, math.sin(self.angle) * self.force)
  -- self:applyAngularImpulse(-1 + 2 * math.random())
  self:setGravityScale(0.1)
end

function EnemyPiece:update(dt)
  PhysicalEntity.update(self, dt)
  if self.dead then
    return
  end
  if self.velx < 3 and self.vely < 3 then
    self.timerStarted = true
  end

  if self.timerStarted then
    self.cleanupTimer = self.cleanupTimer + dt
    if self.cleanupTimer > self.CLEANUP_TIME then
      self.dead = true
      tween(self.color, 1, {[4] = 0}, nil, function() self.world = nil end)
    end
  end
end

function EnemyPiece:draw()
  -- love.graphics.setShader(assets.shaders.glitch)
  -- assets.shaders.glitch:send("intensity", 1)
  self:drawImage()
  -- love.graphics.setShader()
end