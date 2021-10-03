Background = class("Background", Entity)

function Background:initialize(width, height, tileData)
  Entity.initialize(self, 0, 0)
  self.layer = 10
  self.width = width
  self.height = height
  self.map = Tilemap:new(assets.images.tileset, TILE_SIZE, TILE_SIZE, width, height)

  for y = 0, #tileData - 1 do
    for x = 0, #tileData[y + 1] - 1 do
      self.map:set(x, y, tileData[y + 1][x + 1] + 1)
    end
  end
end

function Background:draw()
  self.map:draw(self.x, self.y)
end
