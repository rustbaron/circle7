MeleeEnemy = class("MeleeEnemy", Enemy)
MeleeEnemy.ABILITIES = {}
MeleeEnemy.ATTACK_DISTANCE = 30
-- MeleeEnemy.image = getRectImage(Enemy.WIDTH, Enemy.HEIGHT, 0, 1, 0)
MeleeEnemy.image = love.graphics.newCanvas(Enemy.WIDTH * 3, Enemy.HEIGHT * 3)
MeleeEnemy.image:renderTo(function() love.graphics.draw(getRectImage(Enemy.WIDTH, Enemy.HEIGHT, 0, 1, 0), Enemy.WIDTH, Enemy.HEIGHT) end)

function MeleeEnemy:initialize(x, y)
  Enemy.initialize(self, x, y)
  self:addAbility("attack", {windup = 0.6, active = 0.1, cooldown = 0.7, damage = 10, distance = 40, movement = 0.5})
  self.color = {0, 1, 0}
  self.map = Spritemap:new(assets.images.melee, 40, 25)
  self.map:add("attack", {2,3,4,3,2}, 25)
  self.animPlayed = false
end

function MeleeEnemy:update(dt)
  self.map:update(dt)
  Enemy.update(self, dt)
end

function MeleeEnemy:activationLoop(dt)
  local playerDist = math.dist(self.x, self.y, self.world.player.x, self.world.player.y)
  self.movingDirection = self.facingDirection
  if playerDist < self.ATTACK_DISTANCE then
    self:triggerAbility("attack")
  end

  if self.activeAbility and self.activeAbility.name == "attack" then
    if self.abilityStage == "active" then
      if not self.hitComplete and self:entityOverlapsAbility(self.world.player) then
        self.hitComplete = true
        self.world.player:damage(self, self.activeAbility.damage)
      end
      if not self.animPlayed then
        self.map:play("attack")
        self:playRandom{assets.sfx.smallSwipe1, assets.sfx.smallSwipe2, assets.sfx.smallSwipe3}
      end
    elseif self.abilityStage == "cooldown" then
      self.map.frame = 1
    end
  else
    self.map.frame = 1
  end
end

function MeleeEnemy:abilityTriggered(ability)
  self.hitComplete = false
  self.animPlayed = false
  self.map.frame = 5
  self:playSound(assets.sfx.meleeWindup, 0.5)
end
