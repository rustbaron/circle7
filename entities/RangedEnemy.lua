RangedEnemy = class("RangedEnemy", Enemy)
RangedEnemy.image = love.graphics.newCanvas(Enemy.WIDTH * 3, Enemy.HEIGHT * 3)
RangedEnemy.image:renderTo(function() love.graphics.draw(getRectImage(Enemy.WIDTH, Enemy.HEIGHT, 0, 1, 1), Enemy.WIDTH, Enemy.HEIGHT) end)

function RangedEnemy:initialize(x, y)
  Enemy.initialize(self, x, y)
  self.shootingRange = 250
  self.idealRange = 150
  self.retreatRange = 60
  self.corneredRange = 30
  self.drawPrediction = false
  self:addAbility("shoot", {windup = 1, active = self.shoot, cooldown = 2, damage = 10})
  self.color = {0, 1, 1}
  self.map = Spritemap:new(assets.images.ranged, 40, 25)
  self.map.frame = 1
end

function RangedEnemy:activationLoop()
  local playerDist = math.dist(self.x, self.y, self.world.player.x, self.world.player.y)
  if playerDist > self.corneredRange and playerDist < self.retreatRange then
    self.movingDirection = math.sign(self.x - self.world.player.x)
  elseif playerDist < self.shootingRange and self.abilityStage ~= "cooldown" then
    self.movingDirection = 0
    self:triggerAbility("shoot")
  else
    self.movingDirection = math.sign((self.idealRange - playerDist) * (self.x - self.world.player.x))
  end
end

function RangedEnemy:shoot()
  local fireX, fireY = self.x, self.y
  local targetX, targetY = predictTarget(self.world.player, fireX, fireY, EnemyProjectile.SPEED)

  self.world:add(
    EnemyProjectile:new(fireX, fireY, math.angle(fireX, fireY, targetX, targetY), self.activeAbility.damage)
  )
  self:playSound(assets.sfx.rangedFire, 0.4)
end

function RangedEnemy:abilityTriggered()
  self:playRandom({assets.sfx.rangedWindup1, assets.sfx.rangedWindup2}, 0.2)
end

function RangedEnemy:draw()
  Enemy.draw(self)
  if self.drawPrediction then
    local targetX, targetY = predictTarget(self.world.player, self.x, self.y, EnemyProjectile.SPEED)
    love.graphics.setColor(0, 1, 1)
    -- love.graphics.line(self.x, self.y, targetX, targetY)
    love.graphics.setPointSize(3)
    love.graphics.points{targetX, targetY}
    love.graphics.setColor(1, 1, 1)
  end

end
