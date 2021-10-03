-- module definition

postfx = {}
postfx.all = {}
postfx.active = true
postfx._scale = 1

-- metatable

setmetatable(postfx, {
  __index = function(_, key)
    return rawget(postfx, "_" .. key)
  end,
  
  __newindex = function(_, key, value)
    if key == "scale" then
      if postfx._scale == value then return end
      postfx._scale = value
      postfx.reset()
    else
      rawset(postfx, key, value)
    end
  end
})

-- Shader class

local Shader = class("Shader")

function Shader:initialize(effect)
  self.effect = effect
  self.active = true
end

function Shader:draw(canvas, alternate)
  love.graphics.setShader(self.effect)
  love.graphics.setCanvas(alternate)
  love.graphics.draw(canvas, 0, 0)
  love.graphics.setShader()
  postfx.swap()
end

-- functions

function postfx.reset()
  for _, v in pairs{"canvas", "alternate", "exclusion"} do
    postfx[v] = love.graphics.newCanvas(love.graphics.width, love.graphics.height)
    postfx[v]:setFilter("nearest", "nearest")
  end
  
  for _, v in ipairs(postfx.all) do
    if v.reset then v:reset() end
  end
end

postfx.init = postfx.reset

function postfx.add(effect)
  if tostring(effect) == "Shader" then
    effect = Shader:new(effect)
  end
  
  postfx.all[#postfx.all + 1] = effect
  if not effect.draw then effect.draw = Shader.draw end
  if effect.init then effect:init() end
  return effect
end

function postfx.addList(...)
  for _, v in ipairs{...} do postfx.add(v) end
end

function postfx.start()
  if not postfx.active then return end
  postfx.alternate:renderTo(love.graphics.clear)
  postfx.exclusion:renderTo(love.graphics.clear)
  love.graphics.setCanvas(postfx.canvas)
  love.graphics.clear()
end

function postfx.stop()
  if not postfx.active then return end
  local canvas = postfx.canvas
  
  for _, v in ipairs(postfx.all) do
    if v.active then
      canvas = v:draw(canvas, postfx.alternate) or postfx.canvas
    end
  end
  
  love.graphics.setCanvas()
  love.graphics.draw(canvas, 0, 0, 0, postfx._scale, postfx._scale)
  love.graphics.draw(postfx.exclusion, postfx._scale, postfx._scale)
end

function postfx.update(dt)
  if not postfx.active then return end
  
  for _, v in ipairs(postfx.all) do
    if v.active and v.update then v:update(dt) end
  end
end

function postfx.include()
  if not postfx.active then return end
  love.graphics.setCanvas(postfx.canvas)
end

function postfx.exclude()
  if not postfx.active then return end
  love.graphics.setCanvas(postfx.exclusion)
end

function postfx.swap()
  postfx.canvas, postfx.alternate = postfx.alternate, postfx.canvas
  postfx.alternate:renderTo(love.graphics.clear)
end
