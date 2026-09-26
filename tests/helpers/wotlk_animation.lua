-- Animation groups shipped in 3.1; Alpha used SetChange before SetFrom/ToAlpha.
local Animation = {}

function Animation.Create(owner)
  local group = { owner = owner, animations = {}, scripts = {}, playing = false }
  function group:SetScript(event, fn)
    self.scripts[event] = fn
  end
  function group:SetLooping(value)
    self.looping = value
  end
  function group:Play()
    self.playing = true
    if self.scripts.OnPlay then
      self.scripts.OnPlay(self)
    end
  end
  function group:Stop()
    self.playing = false
    if self.scripts.OnStop then
      self.scripts.OnStop(self)
    end
  end
  function group:IsPlaying()
    return self.playing
  end
  function group:CreateAnimation(kind)
    assert(kind == "Alpha", "Add a verified legacy animation type before using it in the fake")
    local animation = {}
    function animation:SetChange(value)
      self.change = value
    end
    function animation:SetDuration(value)
      self.duration = value
    end
    function animation:SetOrder(value)
      self.order = value
    end
    function animation:SetEndDelay(value)
      self.endDelay = value
    end
    function animation:SetStartDelay(value)
      self.startDelay = value
    end
    function animation:SetSmoothing(value)
      self.smoothing = value
    end
    self.animations[#self.animations + 1] = animation
    return animation
  end
  return group
end

return Animation
