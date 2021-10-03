Tilemap = class("Tilemap")

function Tilemap:__index(key)
  return rawget(self, "_" .. key) or self.class.__instanceDict[key]
end

function Tilemap:initialize(img, tw, th, width, height)
  self.visible = true
  self._image = type(img) == "string" and love.graphics.newImage(img) or img
  self._width = width
  self._height = height
  self._columns = math.floor(width / tw)
  self._rows = math.floor(height / th)
  self._tileWidth = tw
  self._tileHeight = th
  self._quads = {}
  self._canvas = love.graphics.newCanvas(width, height)
  self.usePositions = false
  
  local imgWidth = self._image:getWidth()
  local imgHeight = self._image:getHeight()

  for y = 0, math.floor(imgHeight / th) - 1 do
    for x = 0, math.floor(imgWidth / tw) - 1 do
      self._quads[#self._quads + 1] = love.graphics.newQuad(x * tw, y * th, tw, th, imgWidth, imgHeight)
    end
  end
end

function Tilemap:draw(x, y, r, sx, sy, ox, oy, kx, ky)
  if not self.visible then return end
  love.graphics.draw(self._canvas, x, y, r, sx, sy, ox, oy, kx, ky)
end

function Tilemap:set(x, y, index)
  local tw = self._tileWidth
  local th = self._tileHeight
  
  if self.usePositions then
    x = math.floor(x / tw)
    y = math.floor(y / th)
  end
  
  love.graphics.setCanvas(self._canvas)
  love.graphics.setScissor(x * tw, y * th, tw, th)
  love.graphics.clear()
  love.graphics.setScissor()
  
  if index > 0 then
    love.graphics.draw(self._image, self._quads[index], x * tw, y * th)
  end
  
  love.graphics.setCanvas()
end

function Tilemap:setRect(x, y, width, height, index)
  local tw = self._tileWidth
  local th = self._tileHeight
  
  if self.usePositions then
    x = math.floor(x / tw)
    y = math.floor(y / th)
    width = math.floor(width / tw)
    height = math.floor(height / th)
  end
  
  love.graphics.setCanvas(self._canvas)
  love.graphics.setScissor(x * tw, y * th, width * tw, height * th)
  love.graphics.clear()
  love.graphics.setScissor()
  
  if index > 0 then
    local quad = self._quads[index]
    
    for i = x, x + width - 1 do
      for j = y, y + height - 1 do
        if index > 0 then love.graphics.draw(self._image, quad, i * tw, j * th) end
      end
    end
  end
  
  love.graphics.setCanvas()
end
