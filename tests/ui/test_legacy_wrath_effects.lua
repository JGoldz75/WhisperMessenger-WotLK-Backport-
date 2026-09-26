local FakeUI = require("tests.helpers.fake_ui")
local HoverFade = require("WhisperMessenger.UI.Helpers.HoverFade")
local PulseGlow = require("WhisperMessenger.UI.ToggleIcon.PulseGlow")
local Base = require("WhisperMessenger.UI.Helpers.Base")

local function group()
  local g = { animations = {}, scripts = {} }
  function g:CreateAnimation()
    local a = {}
    function a:SetChange(v)
      self.change = v
    end
    function a:SetDuration(v)
      self.duration = v
    end
    function a:SetEndDelay(v)
      self.delay = v
    end
    function a:SetOrder(v)
      self.order = v
    end
    table.insert(self.animations, a)
    return a
  end
  function g:SetScript(k, v)
    self.scripts[k] = v
  end
  function g:SetLooping(v)
    self.looping = v
  end
  function g:IsPlaying()
    return self.playing
  end
  function g:Play()
    self.playing = true
    if self.scripts.OnPlay then
      self.scripts.OnPlay(self)
    end
  end
  function g:Stop()
    self.playing = false
    if self.scripts.OnStop then
      self.scripts.OnStop(self)
    end
  end
  return g
end

return function()
  local factory = FakeUI.NewFactory()
  local frame = factory.CreateFrame("Frame")
  local texture = frame:CreateTexture()
  local animation = group()
  texture.CreateAnimationGroup = function()
    return animation
  end
  texture:Hide()
  local fade = HoverFade.Attach(texture)
  fade.set(true)
  assert(animation.animations[1].change == 1, "legacy hover must animate alpha with SetChange")
  animation.scripts.OnFinished()
  fade.set(false)
  assert(animation.animations[1].change == -1, "legacy hover must fade out with negative change")

  local create = factory.CreateFrame
  factory.CreateFrame = function(...)
    local result = create(...)
    result.CreateAnimationGroup = group
    return result
  end
  local pulse = PulseGlow.Create(factory, frame)
  pulse.start()
  assert(pulse.animation.animations[1].change == 0.8, "legacy glow must fade in")
  assert(pulse.animation.animations[2].change == -0.8, "legacy glow must fade out")
  pulse.stop()
  assert(not pulse.glowFrame:IsShown(), "legacy glow must hide after stopping")

  local gradient = {}
  function gradient:SetTexture(...)
    self.color = { ... }
  end
  function gradient:SetGradientAlpha(...)
    self.gradient = { ... }
  end
  Base.applyHorizontalFade(gradient, { 0.2, 0.4, 0.6, 0.5 })
  assert(gradient.gradient and gradient.gradient[1] == "HORIZONTAL", "Wrath gradients must use SetGradientAlpha")
  assert(gradient.gradient[5] == 0.5 and gradient.gradient[9] == 0, "legacy gradient alpha endpoints must remain accurate")
end
