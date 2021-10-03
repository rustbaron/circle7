HUD = class("HUD", Entity)

function HUD:initialize()
  Entity.initialize(self)
  self.layer = 0
  local rawWidth = love.graphics.width * postfx.scale
  local rawHeight = love.graphics.height * postfx.scale
  self.health = Text:new{
    x=0, width=rawWidth, padding=25, font=assets.fonts.main[60], shadow=true
  }
  self.health.y = rawHeight - self.health.fontHeight - 50
  self.canvas = love.graphics.newCanvas(rawWidth, rawHeight)

  self.title = Text:new{
    text="CIRCLE 7",
    align="center",
    x=0, y=100, width=rawWidth, padding=25, font=assets.fonts.main[160], shadow=true
  }
  self.continue = Text:new{
    text="Press enter to continue",
    align="center",
    x=0, y=rawHeight / 2 + 100, width=rawWidth, padding=25, font=assets.fonts.main[60], shadow=true
  }
  self.instructions = Text:new{
    text="Move -> A / D\nJump -> W / Space\nLight attack -> Left click\nStrong attack -> Shift / middle click\nParry -> Right click",
    x=0, width=rawWidth, padding=25, font=assets.fonts.main[48], shadow=true
  }
  self.instructions.y = rawHeight - self.instructions.fontHeight * 5 - 50
  self.instructions.color[4] = 0
  self.instructions2 = Text:new{
    text="Deal damage to increase stability\nParry just before an attack lands\nParry both melee and projectiles\nCombine light and heavy attacks\nKeep moving",
    x=0, align="right", width=rawWidth, padding=25, font=assets.fonts.main[36], shadow=true
  }
  self.instructions2.y = rawHeight - self.instructions2.fontHeight * 5 - 50
  self.instructions2.color[4] = 0

  self.welcome = Text:new{
    text="Welcome back...",
    align="center",
    x=0, y=rawHeight / 2, width=rawWidth, padding=25, font=assets.fonts.main[60], shadow=true
  }
  self.welcome.color[4] = 0
end

function HUD:update(dt)
  self.health.text = math.ceil(self.world.player.health)
end

function HUD:draw()
  self.world.camera:unset()
  self.canvas:renderTo(function()
    love.graphics.clear()
    if self.titleMode then
      self.title:draw()
      self.continue:draw()
      self.instructions:draw()
      self.instructions2:draw()
    else
      self.health:draw()
      self.welcome:draw()
    end
  end)
  
  local intensity = self.titleMode and GLITCH_SCALE * 10 or 0.5 + 3 * (1 - self.world.player.health / 100)
  love.graphics.setShader(assets.shaders.glitch)
  assets.shaders.glitch:send("intensity", intensity)
  love.graphics.draw(self.canvas)
  love.graphics.setShader()
  self.world.camera:set()
end

function HUD:showInstructions()
  tween(self.instructions.color, 0.5, {[4] = 1})
  tween(self.instructions2.color, 0.5, {[4] = 1})
end

function HUD:showWelcome()
  delay(1, function()
    tween(self.welcome.color, 1, {[4] = 1}, nil, function()
      delay(2, function()
        tween(self.welcome.color, 1, {[4] = 0})
      end)
    end)
  end)
end