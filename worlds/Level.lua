Level = class("Level", PhysicalWorld)

function Level:initialize(levelName, playerHealth)
  PhysicalWorld.initialize(self)
  self.name = levelName or "1"
  self:setupLayers({
    [0] = {0, pre=postfx.exclude, post=postfx.include}, -- hud
    [1] = 1, -- bg1
    [2] = 1, -- floor
    [3] = 1, -- lighting
    [6] = 1, -- player
    [7] = 1, -- effects
    [8] = 1, -- enemies
    [10] = 1, -- walls
  })

  local fileContent = love.filesystem.read("assets/levels/" .. self.name .. ".json")
  self.data = json.decode(fileContent)
  self.width = self.data.width
  self.height = self.data.height
  self.camera:setBounds(0, 0, self.width, self.height)
  self.shakeTimer = 0
  self.initPlayerHealth = playerHealth or 100

  Enemy.all:clear()
  self:addTiles()
  self:addEntities()
  self.hud = HUD:new()
  self.lighting = Lighting:new()
  self:add(self.lighting, self.hud)
  
  if levelName == "8" then
    self:setGravity(0, 500)
  elseif levelName == "7" then
    self:setGravity(0, 1000)
  elseif levelName == "6" then
    self:setGravity(0, 3000)
  else
    self:setGravity(0, 7000)
  end
end

function Level:start()
  PhysicalWorld.start(self)
  TIME_SCALE = 1
  GLITCH_SCALE = 1
  if self.name ~= "title" then
    LAST_LEVEL = self.name
  end
  self.camera.x = self.player.x
  self.camera.y = self.player.y
  self.camera:bind()
  tween(_G, 0.5, {GLITCH_SCALE = 0.1})
  if self.name == "1" then
    self.hud:showWelcome()
  end
end

function Level:addTiles()
  self.floor = Floor:new(self.width, self.height, self:getLayerData("Floor Layer"), self:getLayerData("Floor Collide"))
  self:add(self.floor)
  self.background = Background:new(self.width, self.height, self:getLayerData("Background"))
  self:add(self.background)
end

function Level:addEntities()
  for _, entity in ipairs(self:getLayerData("Entities")) do
    if entity.name == "Player" then
      self.player = Player:new(entity.x, entity.y)
      self.player.health = self.initPlayerHealth
      self:add(self.player)
    elseif entity.name == "MeleeEnemy" then
      self:add(MeleeEnemy:new(entity.x, entity.y))
    elseif entity.name == "RangedEnemy" then
      self:add(RangedEnemy:new(entity.x, entity.y))
    elseif entity.name == "Light" then
      self:add(Light.fromData(entity))
    elseif entity.name == "LevelEnd" then
      self:add(LevelEnd:new(entity.x, entity.y, entity.width, entity.height, entity.values.next))
    end
  end
end

function Level:update(dt)
  PhysicalWorld.update(self, dt)

  if self.shakeTimer > 0 then
    local amount = self.shakeEasing(self.shakeTimer / self.shakeTime) * self.shakeAmount * 0.8 + self.shakeAmount * 0.2
    self.shakeX = amount * (1 - 2 * math.random(0, 1))
    self.shakeY = amount * (1 - 2 * math.random(0, 1))
    self.shakeTimer = self.shakeTimer - dt
  else
    self.shakeX = 0
    self.shakeY = 0
  end

  self.camera.x = math.lerp(self.camera.x, self.player.x, 0.2)
  self.camera.y = math.lerp(self.camera.y, self.player.y, 0.2)
  self.camera:bind()
  self.camera.x = self.camera.x + self.shakeX
  self.camera.y = self.camera.y + self.shakeY
end

function Level:shake(amount, time, easing)
  self.shakeAmount = amount
  time = time or 1
  self.shakeTimer = time
  self.shakeTime = time
  self.shakeEasing = easing or ease.quadIn
end

function Level:getLayerData(name)
  for i, layer in ipairs(self.data.layers) do
    if layer.name == name then
      return layer.entities or layer.data2D
    end
  end

  error("No layer named: " .. name)
end
