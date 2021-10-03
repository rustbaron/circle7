Text = class("Text")

function Text:__index(key)
  return rawget(self, "_" .. key) or self.class.__instanceDict[key]
end

function Text:__newindex(key, value)
  if key == "text" then
    self._text = tostring(value)
    if self._font then self._fontWidth = self._font:getWidth(value) end
  elseif key == "font" then
    self._font = value
    self:_setFontValues()
  elseif key == "lineHeight" then
    self._lineHeight = value
    self._font:setLineHeight(value)
  else
    rawset(self, key, value)
  end
end
  
function Text:initialize(t)
  self.x = t.x or 0
  self.y = t.y or 0
  self.align = t.align or "left"
  self.width = t.width or love.graphics.width
  self.color = t.color or { 1, 1, 1, 1 }
  self.shadow = t.shadow or false
  self.padding = t.padding or 0
  self._text = t[1] or t.text or ""
    
  if t.font then
    self._font = t.font
    self:_setFontValues()
  end
end

function Text:draw(x, y)
  local prevFont = love.graphics.getFont()
  if self._font then love.graphics.setFont(self._font) end
  love.graphics.storeColor()

  x = (x or self.x) + self.padding
  y = (y or self.y) + self.padding
  width = self.width - self.padding * 2

  if self.shadow then
    love.graphics.setColor(0.05, 0.05, 0.05, self.color[4])
    love.graphics.printf(self._text, x + 1, y + 2, width, self.align)
  end

  love.graphics.setColor(self.color)
  love.graphics.printf(self._text, x, y, width, self.align)
  love.graphics.resetColor()
  if prevFont then love.graphics.setFont(prevFont) end
end

function Text:_setFontValues()
  self._lineHeight = self._font:getLineHeight()
  self._fontWidth = self._font:getWidth(self._text)
  self._fontHeight = self._font:getHeight()
end
