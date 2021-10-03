EnemyProjectile = class("EnemyProjectile", PhysicalEntity)
EnemyProjectile.SPEED = 500
EnemyProjectile.WIDTH = 16
EnemyProjectile.HEIGHT = 2
EnemyProjectile.PARRY_MULT = 6
EnemyProjectile.image = getRectImage(EnemyProjectile.WIDTH, EnemyProjectile.HEIGHT)
EnemyProjectile.NORMAL_COLOR = {0, 1, 1}
EnemyProjectile.PARRY_COLOR = {1, 0, 0}

function EnemyProjectile:initialize(x, y, angle, damage)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.layer = 6
  self.width = EnemyProjectile.WIDTH
  self.height = EnemyProjectile.HEIGHT
  self.angle = angle
  self.damage = damage
  self.dead = false
  self.parried = false

  self.color = self.NORMAL_COLOR
  self.light = Light:new(Light.createCircularImage(250, 2))
  self.light.color = self.color
  self.ps = love.graphics.newParticleSystem(assets.images.tinyParticle, 500)
  self.ps:setSpread(math.tau / 32)
  self.ps:setDirection((angle + math.tau / 2) % math.tau)
  self.ps:setLinearDamping(0.5)
  self.ps:setColors(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], 1, self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], 0.7, self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], 0)
  self.ps:setParticleLifetime(2, 3)
  self.ps:setSizes(0.5, 0.1)
  self.ps:setSizeVariation(0.5)
  self.ps:setEmitterLifetime(-1)
  self.ps:setEmissionRate(500)
  self.ps:setSpeed(5, 100)
  self.ps:setLinearAcceleration(math.cos(angle) * 10, math.sin(angle) * 10, math.cos(angle) * 50, math.sin(angle) * 50)
  self.ps:setPosition(x, y)
end

function EnemyProjectile:added()
  self:setupBody()
  self:setGravityScale(0)
  self:setBullet(true)
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width / 2, self.height))
  self.fixture:setSensor(true)
  self.fixture:setCategory(5)
  self.fixture:setMask(3, 5)
  self.world:add(self.light)
end

function EnemyProjectile:removed()
  self.world:remove(self.light)
end

function EnemyProjectile:update(dt)
  self.ps:update(dt)
  if self.dead then
    if self.ps:getCount() <= 0 then
      self.world = nil
    end
    return
  end

  PhysicalEntity.update(self, dt)

  if self.shouldParryTo then
    self.fixture:setMask(5)

    if self.shouldParryTo ~= true then
      local targetX, targetY = predictTarget(self.shouldParryTo, self.x, self.y, self.SPEED)
      self.angle = math.angle(self.x, self.y, targetX, targetY)
    else
      self.angle = math.angle(self.world.player.x, self.world.player.y, self.x, self.y)
    end


    self.ps:setColors(self.PARRY_COLOR[1], self.PARRY_COLOR[2], self.PARRY_COLOR[3], 1, self.PARRY_COLOR[1], self.PARRY_COLOR[2], self.PARRY_COLOR[3], 0.7, self.PARRY_COLOR[1], self.PARRY_COLOR[2], self.PARRY_COLOR[3], 0)
    self.color = self.PARRY_COLOR
    self.light.color = self.color
    self.shouldParryTo = nil
  end

  self.velx = self.SPEED * math.cos(self.angle)
  self.vely = self.SPEED * math.sin(self.angle)
  self.light.x = self.x
  self.light.y = self.y
  self.ps:setPosition(self.x, self.y)
end

function EnemyProjectile:draw()
  if not self.dead then
    self:drawImage()
  end
  love.graphics.draw(self.ps)
end

function EnemyProjectile:parry(enemy)
  self.parried = true
  self.shouldParryTo = enemy or true
end

function EnemyProjectile:collided(other)
  if self.dead then
    return
  end
  if not self.parried and other:isInstanceOf(Player) then
    other:damage(self, self.damage)
    if not self.parried then
      self:die()
    end
  else
    if self.parried and other:isInstanceOf(Enemy) then
      local damage = self.damage * self.PARRY_MULT
      other:damage(self, damage)
      self.world.player:applyLifesteal(damage)
    end
    self:die()
  end
end

function EnemyProjectile:die()
  self.dead = true
  self.world = nil
end
