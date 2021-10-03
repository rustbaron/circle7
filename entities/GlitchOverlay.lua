GlitchOverlay = class("GlitchOverlay", Entity)

function GlitchOverlay:initialize()
  Entity.initialize(self)
  self.canvas = love.graphics.newCanvas(love.graphics.width, love.graphics.height)
  self.layer = 2
  self.time = 0
end

function GlitchOverlay:update(dt)
  self.time = self.time + dt
end

function GlitchOverlay:draw()
  self.world.camera:unset()
  -- love.graphics.rectangle("fill", 0, 0, love.graphics.width, love.graphics.height)
  love.graphics.setCanvas(postfx.alternate)
  love.graphics.setShader(assets.shaders.glitchArea)
  assets.shaders.glitchArea:send("map", self.canvas)
  assets.shaders.glitchArea:send("time", self.time)
  love.graphics.draw(postfx.canvas, 0, 0)
  -- love.graphics.draw(self.canvas, 0, 0)
  love.graphics.setShader()
  self.canvas:renderTo(function() love.graphics.clear(0,0,0,1) end)
  postfx.swap()
  self.world.camera:set()
end

function GlitchOverlay:drawArea(x, y, radius, intensity)
  self.canvas:renderTo(function()
    love.graphics.draw(Light.createCircularImage(radius, 2, intensity), x, y)
  end)
end