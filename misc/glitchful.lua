glitchful = {}
glitchful.active = true

function glitchful:init()
  self.effect = assets.shaders.glitch
  self.timeElapsed = 0
end

function glitchful:update(dt)
  self.timeElapsed = self.timeElapsed + dt
  assets.shaders.glitch:send("elapsed_time", self.timeElapsed)
end

function glitchful:draw(canvas, alternate)
  assets.shaders.glitch:send("intensity", GLITCH_SCALE)
  love.graphics.setShader(self.effect)
  love.graphics.setCanvas(alternate)
  love.graphics.draw(canvas, 0, 0)
  love.graphics.setShader()
  postfx.swap()
end