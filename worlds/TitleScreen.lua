TitleScreen = class("TitleScreen", Level)

function TitleScreen:initialize()
  Level.initialize(self, "title", 100)
  self.player.locked = true
  self.player.map.frame = 19
  self.player.effectGlitch = 1
  self.player.heavyPS:start()
  self.camera.zoom = 2.5
  self.hud.titleMode = true
  self.shownInstructions = false
  GLITCH_SCALE = 0.5
end

function TitleScreen:update(dt)
  Level.update(self, dt)
  -- self.camera.x = self.player.x + love.graphics.width / 4
  -- self.camera.y = self.player.y + love.graphics.height / 4
  self.camera.x = self.player.x + 35
  self.camera.y = self.player.y
  if input.pressed("continue") then
    if self.shownInstructions then
      tween(_G, 2, {GLITCH_SCALE = 20}, ease.quadIn, function()
        ammo.world = Level:new(LAST_LEVEL)
      end)
    else
      self.hud:showInstructions()
      self.shownInstructions = true
    end
  end
end

function TitleScreen:draw()
  Level.draw(self)

end

