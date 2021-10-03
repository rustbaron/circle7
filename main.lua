require("lib.ammo.all")
ammo.db = require("lib.ammo.debug")
require("lib.gfx")
input = require("lib.ammo.input")
json = require("lib.json.json")


require("utils")
require("misc.noise")
require("misc.glitchful")
require("worlds.Level")
require("worlds.TitleScreen")
require("entities.HUD")
require("entities.Floor")
require("entities.Background")
require("entities.Agent")
require("entities.Player")
require("entities.Enemy")
require("entities.MeleeEnemy")
require("entities.RangedEnemy")
require("entities.EnemyProjectile")
require("entities.Light")
require("entities.Lighting")
require("entities.GlitchOverlay")
require("entities.EnemyPiece")
require("entities.LevelEnd")

TILE_SIZE = 11
TIME_SCALE = 1
GLITCH_SCALE = 0.1
local timeElapsed = 0

function love.load()
  love.audio.setDistanceModel("linear")
  loadAssets()
  defineInputMappings()

  postfx.init()
  postfx.add(noise)
  postfx.add(glitchful)
  -- lighting:init()
  -- postfx.add(lighting)
  -- postfx.active = false
  postfx.scale = math.ceil(love.graphics.width / 500)
  love.graphics.width = love.graphics.width / postfx.scale
  love.graphics.height = love.graphics.height / postfx.scale

  ammo.db.init()
  ammo.db.addInfo("Ability", function()
    return (ammo.world and ammo.world.player and ammo.world.player.activeAbility) and (
      ammo.world.player.activeAbility.name .. " " .. ammo.world.player.abilityStage .. " " .. ammo.world.player.abilityTimer
    )
  end)
  function ammo.db.commands:level(name)
    ammo.world = Level:new(name)
  end

  ammo.world = TitleScreen:new()
  BG_MUSIC = assets.music.music:play()
  BG_MUSIC:setLooping(true)
  BG_MUSIC:setVolume(0.2)

  -- assets.shaders.glitch:send("Apply_To_Specific_Color", true);
  assets.shaders.glitch:sendColor("Color_To_Replace", {53/255, 60/255, 97/255, 1})
end

function love.update(dt)
  dt = TIME_SCALE * dt
  if GLITCH_SCALE > 0.1 then
    GLITCH_SCALE = GLITCH_SCALE - 0.2 * dt
  end
  ammo.update(dt)
  postfx.update(dt)
  timeElapsed = timeElapsed + dt
  assets.shaders.glitch:send("elapsed_time", timeElapsed)
  ammo.db.update(dt)
  input.update()
end

function love.draw()
  postfx.start()
  -- assets.shaders.glitch:send("intensity", GLITCH_SCALE)
  ammo.draw()
  -- love.graphics.setShader(assets.shaders.glitch)
  postfx.stop()
  -- love.graphics.setShader()
  ammo.db.draw()
end

function love.keypressed(key, code)
  if key == "m" then
    if BG_MUSIC:isPlaying() then
      BG_MUSIC:pause()
    else
      BG_MUSIC:play()
    end
  end

  input.keypressed(key)
  ammo.db.keypressed(key, code)
end

function love.wheelmoved(dx, dy)
  ammo.db.wheelmoved(dx, dy)
  input.wheelmoved(dx, dy)
end

function loadAssets()
  assets.newFont("square.ttf", { 160, 60, 48, 36 }, "main")
  assets.images("tileset.png", "player.png", "tiny-particle.png", "melee.png", "ranged.png")
  assets.shaders("glitch.frag", "glitch-area.frag", "noise.frag")
  assets.music("music.mp3")
  assets.sfx(
    "heavy-windup.ogg", "heavy-hit.ogg", "small-swipe-1.ogg", "small-swipe-2.ogg", "small-swipe-3.ogg",
    "parry.ogg", "slow-down.ogg", "hit1.ogg", "hit2.ogg", "hit3.ogg", "melee-windup.ogg", "death.ogg",
    "enemy-death-1.ogg", "enemy-death-2.ogg", "enemy-death-3.ogg", "ranged-windup-1.ogg",  "ranged-windup-2.ogg",
    "ranged-fire.ogg"
  )
  for _, v in pairs(assets.images) do v:setFilter("nearest", "nearest") end
end

function defineInputMappings()
  input.define("left", "left", "a")
  input.define("right", "right", "d")
  input.define("jump", "up", "w", "space")
  input.define{"light", mouse = 1}
  input.define{"heavy", key = "lshift", mouse = 3}
  input.define{"parry", mouse = 2}
  input.define("continue", "return")
end

function glitchDamage(amount)
  GLITCH_SCALE = math.min(GLITCH_SCALE + amount / 100 * 0.2, 1)
end


