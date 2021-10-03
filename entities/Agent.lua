Agent = class("Agent", PhysicalEntity)

function Agent:initialize(x, y, width, height)
  PhysicalEntity.initialize(self, x, y, "dynamic")
  self.id = math.random(100000000)
  self.width = width
  self.height = height
  self.facingDirection = 1
  self.movingDirection = 0
  self.abilities = {}
  self.health = 100
  self.dead = false
  self.moveForce = 60000
  self.jumpImpulse = 30000
  self.attackHeight = 50
  self.scaleX = 1
  self.effectGlitch = 0

  self.abilities = {}
  self.activeAbility = nil
  self.abilityTimer = 0
  self.abilityStage = nil
  self.drawAbilityBox = false
  self.drawBoundingBox = false
  self.trackedSources = LinkedList:new()
end

function Agent:addAbility(name, t)
  t.name = name
  self.abilities[name] = t
end

function Agent:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setCategory(2)
  self:setMass(10)
  self:setLinearDamping(15)
end

function Agent:update(dt)
  PhysicalEntity.update(self, dt)
  if self.dead then
    return
  end

  self:setAngularVelocity(0)
  self.angle = 0

  if self.health <= 0 then
    self:die()
  end

  local movementFactor = 1
  if self.activeAbility and self.activeAbility.movement and (
    self.abilityStage == "windup" or self.abilityStage == "active"
  ) then
    movementFactor = self.activeAbility.movement
  end
  self:applyForce(self.moveForce * self.movingDirection * movementFactor, 0)
  
  -- ability timers/stages
  if self.abilityTimer and self.abilityTimer > 0 then
    self.abilityTimer = self.abilityTimer - dt
    if self.abilityTimer <= 0 then
      if self.abilityStage == "windup" then
        if type(self.activeAbility.active) == "number" then
          self.abilityStage = "active"
          self.abilityTimer = self.activeAbility.active
        else
          self.activeAbility.active(self)
          self.abilityStage = "cooldown"
          self.abilityTimer = self.activeAbility.cooldown
        end
      elseif self.abilityStage == "active" then
        self.abilityStage = "cooldown"
        self.abilityTimer = self.activeAbility.cooldown
      else
        self.abilityTimer = 0
        self.abilityStage = nil
        self.activeAbility = nil
      end
    end
  end

  self.scaleX = self.facingDirection

  for elem in self.trackedSources:iterate() do
    if not elem.source:isPlaying() then
      self.trackedSources:remove(elem)
    else
      elem.source:setPosition(self.x, self.y)
      -- elem.source:setVelocity(self.velx, self.vely)
    end
  end
end

function Agent:die()
  self.dead = true
end

function Agent:damage(from, amount, force, direction)
  self.health = self.health - amount
  if force then
    self:applyLinearImpulse(force * math.cos(direction), force * math.sin(direction))
  end
  ammo.db.log(self, self.id, "damaged from", from, "for", amount)
end

function Agent:jump()
  if math.round(self.vely * 1000) == 0 then
    self:applyLinearImpulse(0, -self.jumpImpulse)
  end
end

function Agent:triggerAbility(name)
  local ability = self.abilities[name]
  if not ability then
    error("No ability with name " .. name)
  end

  if not self.activeAbility or (
    (ability.interrupts or self.activeAbility.interruptable)
    and ability.name ~= self.activeAbility.name
  ) then
    self:abilityTriggered(ability)
    self.activeAbility = ability

    if ability.windup and ability.windup > 0 then
      self.abilityStage = "windup"
      self.abilityTimer = ability.windup
    else
      self.abilityStage = "active"
      self.abilityTimer = ability.active
    end

    ammo.db.log(self, self.id, "used ability", ability.name, "now in", self.abilityStage)
  end
end

function Agent:cancelAbility()
  self.activeAbility = nil
  self.abilityTimer = 0
  self.abilityStage = nil
end

function Agent:abilityTriggered(ability)
end

function Agent:getAbilityBoundingBox()
  local x1, x2 = self.x, self.x + self.activeAbility.distance * self.facingDirection
  if x2 < x1 then
    x1, x2 = x2, x1
  end
  return x1, self.y - self.attackHeight / 2, x2, self.y + self.attackHeight / 2
end

function Agent:entityOverlapsAbility(entity)
  local aMinX, aMinY, aMaxX, aMaxY = self:getAbilityBoundingBox()
  local eMinX, eMinY, eMaxX, eMaxY = entity.fixture:getBoundingBox()
  return doBoxesOverlap(aMinX, aMinY, aMaxX, aMaxY, eMinX, eMinY, eMaxX, eMaxY)
end

function Agent:draw()
  if self.drawAbilityBox and self.activeAbility and self.abilityStage == "active" and self.activeAbility.distance then
    local x1, y1, x2, y2 = self:getAbilityBoundingBox()
    love.graphics.setColor(1, 0, 0, 0.3)
    love.graphics.rectangle("fill", x1, y1, (x2 - x1), (y2 - y1))
  end

  if self.drawBoundingBox then
    local x1, y1, x2, y2 = self.fixture:getBoundingBox()
    love.graphics.setColor(0, 1, 0, 0.7)
    love.graphics.rectangle("line", x1, y1, (x2 - x1), (y2 - y1))
  end
end

function Agent:applyShader()
  assets.shaders.glitch:send("intensity", self.effectGlitch * 0.5 + (1 - self.health / 100))
  love.graphics.setShader(assets.shaders.glitch)
end

function Agent:playSound(sound, volume)
  local src = playSound(sound, volume, self.x, self.y)
  self.trackedSources:push({source = src})
  return src
end

function Agent:playRandom(sound, volume)
  local src = playRandom(sound, volume, self.x, self.y)
  self.trackedSources:push({source = src})
  return src
end
