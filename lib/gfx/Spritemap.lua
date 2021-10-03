Spritemap = class("Spritemap")

function Spritemap:__index(key)
  return rawget(self, "_" .. key) or self.class.__instanceDict[key]
end

function Spritemap:__newindex(key, value)
  if key == "frame" then
    if rawget(self, "_current") then self:stop() end
    self._frame = value
  else
    rawset(self, key, value)
  end
end

function Spritemap:initialize(img, fw, fh, callback, ...)
  self.active = true
  self.visible = true
  self._frame = 1
  self._image = type(img) == "string" and love.graphics.newImage(img) or img
  self._width = fw
  self._height = fh
  self._quads = {}
  self._animations = {}  
  
  local iw = self._image:getWidth()
  local ih = self._image:getHeight()
  self._columns = math.floor(iw / fw)
  self._rows = math.floor(ih / fh)
  
  for y = 0, self._rows - 1 do
    for x = 0, self._columns - 1 do
      self._quads[#self._quads + 1] = love.graphics.newQuad(x * fw, y * fh, fw, fh, iw, ih)
    end
  end
  
  if callback then self:setCallback(callback, ...) end
  self:stop()
end

function Spritemap:update(dt)
  if not self.active then return end
  
  if self._current then
    local anim = self._animations[self._current]
    
    if self._timer <= 0 then
      self._timer = self._timer + anim.time
      
      if self._animIndex == #anim.frames and not anim.loop then
        self:stop()
        if self.callback then self.callback(unpack(self.callbackArgs)) end
      else
        self._animIndex = self._animIndex % #anim.frames + 1
        self._frame = anim.frames[self._animIndex]
      end
    else
      self._timer = self._timer - dt
    end
  end
end

function Spritemap:draw(x, y, r, sx, sy, ox, oy, kx, ky)
  if not self.visible then return end
  love.graphics.draw(self._image, self._quads[self._frame], x, y, r, sx, sy, ox, oy, kx, ky)
end

function Spritemap:add(name, frames, rate, loop)
  self._animations[name] = { frames = frames, loop = loop, time = 1 / rate }
end

function Spritemap:play(name)
  if self._current == name then
    return
  end
  
  self._current = name
  self._timer = self._animations[name].time
  self._frame = self._animations[name].frames[1]
  self._animIndex = 1
end

function Spritemap:stop()
  self._current = nil
end

function Spritemap:setCallback(callback, ...)
  self.callback = callback
  self.callbackArgs = { ... }
end
