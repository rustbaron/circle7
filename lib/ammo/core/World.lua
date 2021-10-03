World = class("World")

function World:__index(key)
  if key == "count" then
    return self._updates._length
  elseif key == "camera" then
    return self._camera
  elseif key == "all" then
    return self._updates:getAll()
  else
    return self.class.__instanceDict[key]
  end
end

function World:__newindex(key, value)
  if key == "camera" then
    if rawget(self, "_camera") then
      self._camera:stop()
      self._camera._world = nil
    end
    
    self._camera = value and value or Camera:new()
    self._camera._world = self
    self._camera:start()
  else
    rawset(self, key, value)
  end
end

function World:initialize()
  self.active = true
  self.visible = true
  
  -- lists
  self._updates = LinkedList:new("_updateNext", "_updatePrev")
  self._layers = { min = 0, max = 0 }
  self._add = {}
  self._remove = {}
  
  self.camera = nil -- set off the default behaviour
end

function World:update(dt)
  -- update lists at beginning of frame
  self:_updateLists()
  
  -- update
  for v in self._updates:iterate() do
    if v.active ~= false then
      v:update(dt)
    end
  end
  
  self.camera:update(dt)
end

local getColor = love.graphics.getColor
local setColor = love.graphics.setColor
local r, g, b, a

function World:draw()
  for i = self._layers.max, self._layers.min, -1 do
    local layer = self._layers[i]
    
    if layer and layer.visible then
      if layer.pre then layer.pre() end
      
      if layer.camera then
        self.camera:set(layer.scale)
      end
      
      for v in layer:iterate(true) do -- reverse
        if v.visible then
          r, g, b, a = getColor()
          v:draw()
          setColor(r, g, b, a)
        end
      end
      
      if layer.camera then self.camera:unset() end
      if layer.post then layer.post() end
    end
  end
end

function World:start() end
function World:stop() end

function World:add(...)
  for _, v in pairs{...} do
    if not v._world then
      self._add[#self._add + 1] = v
      v._additionQueued = true
    end
  end
end

function World:remove(...)
  for _, v in pairs{...} do
    if v._world == self and not v._removalQueued then
      self._remove[#self._remove + 1] = v
      v._removalQueued = true
    end
  end
end

function World:removeAll()
  for e in self._updates:iterate() do
    self._remove[#self._remove + 1] = v
    v._removeQueued = true
  end
end

function World:addLayer(index, scale, pre, post, camera)
  local layer = LinkedList:new("_drawNext", "_drawPrev")
  
  if type(index) == "table" then
    index = index[1] or index.index
    scale = index[2] or index.scale
    pre = index.pre
    post = index.post
    camera = index.camera
  end
  
  layer.scale = scale or 1
  layer.pre = pre
  layer.post = post
  layer.camera = camera ~= false
  layer.visible = true
  self._layers[index] = layer
  self._layers.min = math.min(index, self._layers.min)
  self._layers.max = math.max(index, self._layers.max)
  return layer
end

function World:setupLayers(t)
  for k, v in pairs(t) do
    if type(v) == "table" then
      last = self:addLayer(k, v[1] or v.scale, v.pre, v.post, v.camera)
    else
      last = self:addLayer(k, v)
    end
  end
end

function World:iterate()
  return self._updates:iterate()
end

function World:_updateLists()
  -- remove
  if #self._remove then
    for _, v in pairs(self._remove) do
      if v.removed then v:removed() end
      self._updates:remove(v)
      v._removalQueued = false
      v._world = nil
      if v._layer then self._layers[v._layer]:remove(v) end
    end
    
    self._remove = {}
  end
  
  -- add
  if #self._add then
    for _, v in pairs(self._add) do
      self._updates:push(v)
      v._additionQueued = false
      v._world = self
      if v._layer then self:_setLayer(v) end
      if v.added then v:added() end
    end
  
    self._add = {}
  end
end

function World:_setLayer(e, prev)
  if self._layers[prev] then self._layers[prev]:remove(e) end
  if not self._layers[e.layer] then self:addLayer(e.layer) end
  self._layers[e.layer]:unshift(e)
end
