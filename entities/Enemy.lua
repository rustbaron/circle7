Enemy = class("Enemy", Agent)
Enemy.all = {}
Enemy.WIDTH = 8
Enemy.HEIGHT = 18

function Enemy.static.resetList()
  Enemy.all = LinkedList:new("_nextEnemy", "_prevEnemy")
end

Enemy.resetList()

function Enemy:initialize(x, y)
  Agent.initialize(self, x, y, Enemy.WIDTH, Enemy.HEIGHT)
  self.activated = false
  self.layer = 7
  self.moveForce = 30000
  self.jumpImpulse = 30000
  self.activationDistance = 300
  self.deactivationDistance = 600
  self.stunTimer = 0
  self.shakeX = 0
  self.shakeY = 0
  self.light = Light:new(Light.createCircularImage(100, 0, 1.1), 100)
  self.light.alpha = 0.1
  self.effectGlitch = 2
  -- self.chunkColour = {1,1,1}
  Enemy.all:push(self)
end

function Enemy:added()
  Agent.added(self)
  self.light.color = self.color
  self.world:add(self.light)
  self.fixture:setCategory(3)
  self.fixture:setMask(3)
end

function Enemy:removed()
  PhysicalEntity.removed(self)
  Enemy.all:remove(self)
  self.world:remove(self.light)
end

function Enemy:update(dt)
  self.light.x = self.x
  self.light.y = self.y

  local playerDist = math.dist(self.x, self.y, self.world.player.x, self.world.player.y)

  if self.stunTimer > 0 then
    self.stunTimer = self.stunTimer - dt
    if self.stunTimer <= 0 then
      self.effectGlitch = 0
    end
  end

  if self.activated then
    if self.stunTimer <= 0 then
      self.facingDirection = math.sign(self.world.player.x - self.x)
      self:activationLoop(dt)

      if self.movingDirection ~= 0 then
        self.world:rayCast(self.x, self.y, self.x + 20 * self.movingDirection, self.y, function(fixt, x, y, xn, yn, fraction)
          local other = fixt:getUserData()
          if other:isInstanceOf(Floor) then
            self:jump()
            return 0
          end
          return 1
        end)
      end
      
      if playerDist >= self.deactivationDistance then
        self.activated = false
        ammo.db.log(self, self.id, "deactivated")
      end
    end
  elseif playerDist <= self.activationDistance then
    self.activated = true
    ammo.db.log(self, self.id, "activated")
  end

  if self.activeAbility and self.abilityStage == "windup" then
    local amount = ease.quadIn(1 - self.abilityTimer / self.activeAbility.windup)
    self.light.alpha = 0.1 + 0.9 * amount
    self.shakeX = amount * 2 * (1 - 2 * math.random(0, 1))
    self.shakeY = amount * 2 * (1 - 2 * math.random(0, 1))
  else
    self.shakeX = 0
    self.shakeY = 0
    self.light.alpha = 0
  end

  Agent.update(self, dt)
end

function Enemy:activationLoop(dt)
end

function Enemy:damage(from, amount, force, dir)
  Agent.damage(self, from, amount, force, dir)
  if self.health > 0 then
    self.effectGlitch = 1
  end
  self.stunTimer = amount / 100
  self.movingDirection = 0
  self:cancelAbility()
  glitchDamage(amount)
  self:playRandom{assets.sfx.hit1, assets.sfx.hit2, assets.sfx.hit3}
end

function Enemy:die()
  if self.dead then
    return
  end
  local playerAngle = math.angle(self.world.player.x, self.world.player.y, self.x, self.y)
  for i = 1, math.random(30, 40) do
    self.world:add(EnemyPiece:new(
      self.x - self.WIDTH / 2 + self.WIDTH * math.random(),
      self.y - self.HEIGHT / 2 + self.HEIGHT * math.random(),
      playerAngle - math.pi / 2 * math.pi * math.random(),
      1 + math.random(),
      self.color
    ))
  end

  self:playRandom({assets.sfx.enemyDeath1, assets.sfx.enemyDeath2, assets.sfx.enemyDeath3}, 0.3)
  self.world = nil
end

function Enemy:draw()
  if self.noDraw then
    return
  end
  self:applyShader()
  if self.map then
    self:drawMap(self.map, self.x + self.shakeX, self.y + self.shakeY)
  else
    self:drawImage(self.image, self.x + self.shakeX, self.y + self.shakeY)
  end
  love.graphics.setShader()
  Agent.draw(self)
end