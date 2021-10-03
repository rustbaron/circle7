function playSound(sound, volume, x, y)
  if type(sound) == "string" then sound = assets.sfx[sound] end
  local src = sound:play(volume)
  if volume then
    src:setVolume(volume)
  end
  if x and y then
    src:setPosition(x, y, 0)
  end
  return src
end

function playRandom(sounds, volume, x, y)
  return playSound(sounds[math.random(1, #sounds)], volume, x, y)
end

function mouseCoords()
  local x, y = love.mouse.getRawPosition()
  return ammo.world.camera:worldPosition(x / postfx.scale, y / postfx.scale)
end

function getRectImage(width, height, r, g, b, a)
  r = r or 1
  g = g or 1
  b = b or 1
  a = a or 1
  
  local data = love.image.newImageData(width, height)
  data:mapPixel(function() return r, g, b, a end)
  return love.graphics.newImage(data)
end

function drawArc(x, y, r, angle1, angle2, segments)
  local i = angle1
  local j = 0
  local step = math.tau / segments
  
  while i < angle2 do
    j = angle2 - i < step and angle2 or i + step
    love.graphics.line(x + (math.cos(i) * r), y - (math.sin(i) * r), x + (math.cos(j) * r), y - (math.sin(j) * r))
    i = j
  end  
end

function Entity:drawImage(image, x, y, color, ox, oy)
  image = image or self.image
  color = color or self.color
  if color then love.graphics.setColor(color) end
  local imageScale = self.imageScale or 1
  local scale = imageScale * (self.scale or 1)
  angle = self.angle
  if self.drawPerpAngle then angle = angle + math.tau / 4 end

  love.graphics.draw(
    image,
    x or self.x,
    y or self.y,
    angle,
    self.scaleX or scale,
    self.scaleY or scale,
    ox or image:getWidth() / 2,
    oy or image:getHeight() / 2
  )
end

function Entity:drawMap(map, x, y, color, ox, oy)
  map = map or self.map
  color = color or self.color
  angle = self.angle
  if self.drawPerpAngle then angle = angle + math.tau / 4 end
  if color then love.graphics.setColor(color) end
  local imageScale = self.imageScale or 1
  local scale = imageScale * (self.scale or 1)
  
  map:draw(
    x or self.x,
    y or self.y,
    angle,
    self.scaleX or scale,
    self.scaleY or scale,
    ox or map.width / 2,
    oy or map.height / 2
  )
end

function doBoxesOverlap(aMinX, aMinY, aMaxX, aMaxY, bMinX, bMinY, bMaxX, bMaxY)
  return aMinX < bMaxX and bMinX < aMaxX and aMinY < bMaxY and bMinY < aMaxY 
end

function predictTarget(target, fireX, fireY, speed)
  local targetX, targetY = target.x, target.y

  -- simple predictive aiming quadratic equation
  local a = target.velx ^ 2 + target.vely ^ 2 - speed ^ 2
  local b = 2 * (target.velx * (target.x - fireX) + target.vely * (target.y - fireY))
  local c = (target.x - fireX) ^ 2 + (target.y - fireY) ^ 2
  local discriminant = b ^ 2 - 4 * a * c

  -- if this is false, we won't hit, but we'll still fire anyway
  if discriminant >= 0 then
    local t1 = (-b + math.sqrt(discriminant)) / (2 * a)
    local t2 = (-b - math.sqrt(discriminant)) / (2 * a)
    local t
    if t1 < 0 then
      t = t2
    elseif t2 < 0 then
      t = t1
    else
      t = t1 < t2 and t1 or t2
    end

    targetX = t * target.velx + target.x
    targetY = t * target.vely + target.y
  end

  return targetX, targetY
end

function levelColorToRGBA(c)
  return tonumber(c:sub(2, 3), 16) / 255, tonumber(c:sub(4, 5), 16) / 255, tonumber(c:sub(6, 7), 16) / 255, tonumber(c:sub(8, 9), 16) / 255
end
