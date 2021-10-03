Player = class("Player", Agent)
Player.WIDTH = 11
Player.HEIGHT = 18
Player.IMAGE = getRectImage(Player.WIDTH, Player.HEIGHT, 1, 0, 0)
Player.DRAIN_RATE = 1
Player.GAIN_SCALE = 0.3
Player.DAMAGE_BOOST_TIME = 0.8
Player.DAMAGE_BOOST_MULT = 2
Player.DAMAGE_RESIST = 0.6

function Player:initialize(x, y)
  Agent.initialize(self, x, y, Player.WIDTH, Player.HEIGHT)

  self.map = Spritemap:new(assets.images.player, 45, 25)
  self.map:add("run", {2,3,4,5,6,7,8,4,3,5}, 25, true)
  self.map:add("inAir", {3,4}, 8, true)
  self.map:add("light", {9,10,11,10,9}, 25)
  self.map:add("heavyWindup", {12,13,14,15,16,17,18,19}, 25)
  self.map:add("heavyHit", {20,21,23,24}, 35)
  self.map:add("parry", {25,26,27}, 25)
  self.map.frame = 1

  self.image = Player.IMAGE
  self.layer = 6
  self.moveForce = 60000
  self.jumpImpulse = 30000
  self.enemiesInAbility = {}
  self.boostTimer = 0
  self.light = Light:new(Light.createCircularImage(200, 0), x, y, 200)

  self:addAbility("light", {windup = 0, active = 0.1, cooldown = 0.3, damage = 35, distance = 40, movement = 0.7})
  self:addAbility("heavy", {windup = 0.7, active = 0.1, cooldown = 0.3, damage = 80, distance = 100, movement = 0.4})
  self:addAbility("parry", {windup = 0, active = 0.5, cooldown = 1, distance = 50, interrupts = true, interruptable = true, movement = 0.7})

  local ps = love.graphics.newParticleSystem(assets.images.tinyParticle, 2000)
  ps:setSpeed(10)
  ps:setTangentialAcceleration(2)
  ps:setParticleLifetime(0.8, 2)
  ps:setEmissionArea("normal", 2, 2)
  ps:setEmissionRate(300)
  ps:setColors(1, 0, 0, 1, 1, 0, 0, 0.8, 1, 0, 0, 0.2)
  ps:setSizes(0.6, 1, 0.6)
  ps:setSpread(math.tau)
  ps:setRadialAcceleration(-10)
  ps:stop()
  self.heavyPS = ps
  self.heavyXOffset = 0
  self.heavyAngle = 0

  ps = love.graphics.newParticleSystem(assets.images.tinyParticle, 2000)
  ps:setSpeed(50)
  ps:setDirection(0)
  ps:setSpread(math.pi)
  ps:setSizes(0.6, 1, 0.6)
  ps:setColors(79/255, 195/255, 247/255, 1, 79/255, 195/255, 247/255, 0.8, 79/255, 195/255, 247/255, 0.2)
  ps:setEmissionRate(500)
  ps:setEmissionArea("normal", 3, 3)
  ps:setLinearDamping(0.5, 1)
  ps:setRadialAcceleration(-10, -50)
  ps:setParticleLifetime(0.3, 0.5)
  ps:stop()
  self.parryPS = ps
  self.parryYOffset = -self.HEIGHT / 4
  self.parryYDir = 1
end

function Player:added()
  Agent.added(self)
  self.world:add(self.light)
  self.fixture:setCategory(2)
end

function Player:update(dt)
  self.heavyAngle = self.heavyAngle + math.tau * dt * 5
  self.heavyPS:update(dt)
  if self.heavyXOffset > 0 then
    self.heavyPS:setPosition(self.x + self.heavyXOffset, self.y + self.HEIGHT / 2)
  else
    self.heavyPS:setPosition(self.x + math.cos(self.heavyAngle) * 20, self.y + math.sin(self.heavyAngle) * 20)
  end
  self.heavyPS:setLinearAcceleration(200 * self.facingDirection, -20, 300 * self.facingDirection, -20)

  self.parryPS:update(dt)
  -- self.parryYOffset = self.parryYOffset + 60 * dt * self.parryYDir
  -- if self.parryYOffset > self.y + self.HEIGHT / 2 or self.parryYOffset < self.y - self.HEIGHT / 2 then
  --   self.parryYDir = self.parryYDir * -1
  -- end
  self.parryPS:setPosition(self.x + self.width / 2 * self.facingDirection, self.y + self.parryYOffset)
  self.parryPS:setDirection(self.facingDirection == 1 and 0 or math.pi)

  self.light.x = self.x
  self.light.y = self.y
  if self.locked then
    return
  end

  self.movingDirection = input.axisDown("left", "right")
  if self.movingDirection ~= 0 then
    self.facingDirection = self.movingDirection
  end
  
  if self.boostTimer > 0 then
    self.boostTimer = self.boostTimer - dt
  end
  
  self.map:update(dt)

  Agent.update(self, dt)
  if self.dead then
    return
  end

  love.audio.setPosition(self.x, self.y, -100)
  self.health = self.health - self.DRAIN_RATE * dt
  if input.pressed("jump") then self:jump() end

  -- ability start / input checking
  for name, _ in pairs(self.abilities) do
    if name ~= "add" and input.pressed(name) then
      local mx, my = mouseCoords()
      if mx > self.x then
        self.facingDirection = 1
      elseif mx < self.x then
        self.facingDirection = -1
      end
      self:triggerAbility(name)
    end
  end

  -- ability usage
  if self.activeAbility and self.abilityStage == "active" then
    if self.activeAbility.name == "heavy" and not self.shakePerformed then
      self.world:shake(8, 0.2)
      self.shakePerformed = true
      self.map:play("heavyHit")
      self.heavyPS:setEmissionRate(1000)
      self:animate(0.2, { heavyXOffset = self.activeAbility.distance * self.facingDirection }, nil, function()
        self.heavyXOffset = 0
        self.heavyPS:setEmissionRate(300)
        self.heavyPS:stop()
      end)
      tween(self.world.camera, 0.1, { zoom = 1})
      tween(self.light.color, 0.1, {1, 1, 1})
      delay(0, function() self.effectGlitch = 0 end)
      self:playSound(assets.sfx.heavyHit)
    end

    if self.activeAbility.name == "light" or self.activeAbility.name == "heavy" then
      -- check for enemies in box
      self:applyToEnemiesInAbility(function(enemy)
        if not self.enemiesInAbility[enemy.id] then
          self.enemiesInAbility[enemy.id] = true
          local force, dir

          if self.activeAbility.name == "light" then
            force = 8000
            dir = self.facingDirection == 1 and 0 or math.pi
          else
            force = 16000
            dir = self.facingDirection == 1 and -math.pi / 4 or math.pi * 5 / 4
          end

          local damage = self.activeAbility.damage * (self.boostTimer > 0 and self.DAMAGE_BOOST_MULT or 1)
          enemy:damage(self, damage, force, dir)
          self:applyLifesteal(damage)
        end
      end)
    end
  end

  if self.activeAbility and self.abilityStage == "cooldown" and self.activeAbility.name == "parry" then
    self.parryPS:stop()
    tween(self.light.color, 0.1, {1, 1, 1})
  end

  -- animation
  if self.map.current ~= "light" and self.map.current ~= "heavyWindup" and self.map.current ~= "heavyHit" and self.map.current ~= "parry" then
    if self.activeAbility and self.activeAbility.name == "heavy" and self.abilityStage == "windup" then
      self.map.frame = 19
    elseif self.activeAbility and self.activeAbility.name == "parry" and self.abilityStage == "active" then
      self.map.frame = 27
    elseif math.abs(self.vely) > 5 then
      self.map:play("inAir")
    elseif math.abs(self.velx) > 50 then
      self.map:play("run")
    else
      self.map.frame = 1
    end
  end
end

function Player:applyToEnemiesInAbility(callback)
  if self.activeAbility and self.activeAbility.distance then
    local aMinX, aMinY, aMaxX, aMaxY = self:getAbilityBoundingBox()
    for enemy in Enemy.all:iterate() do
      if enemy.fixture and enemy.world == self.world then
        local eMinX, eMinY, eMaxX, eMaxY = enemy.fixture:getBoundingBox()
        if aMinX < eMaxX and eMinX < aMaxX and aMinY < eMaxY and eMinY < aMaxY then
          callback(enemy)
        end
      end
    end
  end
end

function Player:abilityTriggered(ability)
  self.enemiesInAbility = {}
  self.shakePerformed = false

  if self.activeAbility then
    if self.colorTween then
      self.colorTween:stop()
      self.colorTween = nil
    end
    if self.zoomTween then
      self.zoomTween:stop()
      self.zoomTween = nil
    end
    if self.glitchTween then
      self.glitchTween:stop()
      self.glitchTween = nil
    end
    if ability.name ~= "parry" then
      self.parryPS:stop()
    elseif ability.name ~= "heavy" then
      self.heavyPS:stop()
      self.zoomTween = self.world.camera:animate(0.1, {zoom = 1})
      self.glitchTween = self:animate(0.1, {effectGlitch = 0})
    end
  end
  
  if ability.name == "light" then
    self.map:play("light")
    self:playRandom{assets.sfx.smallSwipe1, assets.sfx.smallSwipe2, assets.sfx.smallSwipe3}
  elseif ability.name == "heavy" then
    self:playSound(assets.sfx.heavyWindup, 1)
    self.map:play("heavyWindup", 0.8)
    self.world:shake(0.5, ability.windup)
    self.glitchTween = self:animate(ability.windup, {effectGlitch = 2})
    self.zoomTween = self.world.camera:animate(ability.windup, {zoom = 1.4})
    self.colortween = tween(self.light.color, ability.windup, {1, 0.2, 0.2})
    self.heavyPS:start()
  elseif ability.name == "parry" then
    self.map:play("parry")
    self.parrySlowdown = false
    self.parryPS:start()
    self.colorTween = tween(self.light.color, ability.windup, {79/255, 195/255, 247/255})
    self:playSound(assets.sfx.parry, 1)
  end

end

function Player:parry(from)
  ammo.db.log("Successful parry against", from, from.id)
  self.world:shake(2, 0.3)
  self.boostTimer = self.DAMAGE_BOOST_TIME
  if not self.parrySlowdown then
    self:playSound(assets.sfx.slowDown, 1.5)
    self.parrySlowdown = true
    self.parryPS:emit(500)
    tween(_G, 0.1, {TIME_SCALE = 0.5}, nil, function()
      delay(0.4, function()
        tween(_G, 0.2, {TIME_SCALE = 1})
      end)
    end)
  end
end

function Player:damage(from, amount, force, direction)
  if self.activeAbility and self.activeAbility.name == "parry" and self.abilityStage == "active" then
    local pMinX, pMinY, pMaxX, pMaxY = self:getAbilityBoundingBox()

    if from:isInstanceOf(MeleeEnemy) then
      local eMinX, eMinY, eMaxX, eMaxY = from:getAbilityBoundingBox()
      if doBoxesOverlap(pMinX, pMinY, pMaxX, pMaxY, eMinX, eMinY, eMaxX, eMaxY) then
        from.stunTimer = 0.5
        return self:parry(from)
      end
    elseif from:isInstanceOf(EnemyProjectile) then
      local eMinX, eMinY, eMaxX, eMaxY = from.fixture:getBoundingBox()
      if doBoxesOverlap(pMinX, pMinY, pMaxX, pMaxY, eMinX, eMinY, eMaxX, eMaxY) then
        local closest = nil
        local closestDist = nil
        for enemy in Enemy.all:iterate() do
          local dist = math.dist(self.x, self.y, enemy.x, enemy.y)

          local angle = math.angle(self.x, self.y, enemy.x, enemy.y)
          if angle > math.pi * 2 then
            angle = angle % (math.pi * 2)
          end
          local angleQ1Q4 = angle > math.pi * 1.5 or angle < math.pi / 2
          if (self.facingDirection ~= 1) ~= angleQ1Q4 and (not closestDist or dist < closestDist) then
            closestDist = dist
            closest = enemy
          end
        end

        from:parry(closest)
        return self:parry(from)
      end
    end
  end

  self:playRandom{assets.sfx.hit1, assets.sfx.hit2, assets.sfx.hit3}
  self.world:shake(5, 0.3)
  Agent.damage(self, from, amount * self.DAMAGE_RESIST, force, direction)
end

function Player:applyLifesteal(damage)
  self.health = math.min(self.health + damage * self.GAIN_SCALE, 100)
end

function Player:die()
  if self.dead then
    return
  end
  Agent.die(self)
  self:animate(1, { effectGlitch = 40 }, ease.quadOut, function() self.noDraw = true end)
  self:playSound(assets.sfx.death)

  delay(1, function()
    ammo.world = Level:new(self.world.name, 100)
  end)
end

function Player:draw()
  love.graphics.draw(self.heavyPS)
  if not self.noDraw then
    self:applyShader()
    self:drawMap()
    love.graphics.setShader()
  end
  love.graphics.draw(self.parryPS)
  Agent.draw(self)
end

