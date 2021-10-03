noise = {}
noise.active = true

function noise:init()
  self.supported = postfx.fxSupported
  self.timer = 0
  self.time = 0.04
  self.effect = assets.shaders.noise
end

function noise:update(dt)
  if self.timer >= self.time then
    -- a 2d random factor seems to reduce the size of the occasional "artifacts"
    self.effect:send("factor", { math.random(), math.random() })

    if ammo.world and ammo.world.player then
      self.effect:send("clamp", 0.96 - 0.03 * (1 - ammo.world.player.health / 100))
    end

    self.timer = self.timer - self.time
  end
  
  self.timer = self.timer + dt
end
