LevelEnd = class("LevelEnd", PhysicalEntity)

function LevelEnd:initialize(x, y, width, height, link)
  PhysicalEntity.initialize(self, x + width / 2, y + height / 2, "static")
  self.width = width
  self.height = height
  self.link = link
end

function LevelEnd:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width, self.height))
  self.fixture:setSensor(true)
  self.fixture:setMask(1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16) -- all except 2, player
end

function LevelEnd:collided(other)
  if other:isInstanceOf(Player) and not self.activated then
    self.activated = true
    if self.link == "final" then
      -- todo
    else
      ammo.world = Level:new(self.link, self.world.player.health)
    end
  end
end