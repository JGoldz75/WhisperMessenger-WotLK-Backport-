return function()
  local Timer = require("WhisperMessenger.Core.LegacyWrath.Timer")
  local frame = { scripts = {}, shown = false }
  function frame:SetScript(event, fn)
    self.scripts[event] = fn
  end
  function frame:Show()
    self.shown = true
  end
  function frame:Hide()
    self.shown = false
  end
  local errors = {}
  local timer = Timer.New(function()
    return frame
  end, function(err)
    errors[#errors + 1] = err
  end)
  local calls = {}
  timer.After(0, function()
    calls[#calls + 1] = "first"
    timer.After(0, function()
      calls[#calls + 1] = "next"
    end)
  end)
  assert(#calls == 0, "After must defer work until the next OnUpdate")
  frame.scripts.OnUpdate(frame, 0.01)
  assert(#calls == 1 and calls[1] == "first", "newly queued callbacks wait a frame")
  frame.scripts.OnUpdate(frame, 0.01)
  assert(#calls == 2 and calls[2] == "next")
  assert(not frame.shown, "idle timer frame must stop updating")

  local ticks = 0
  local ticker = timer.NewTicker(0.5, function()
    ticks = ticks + 1
  end)
  frame.scripts.OnUpdate(frame, 0.25)
  assert(ticks == 0)
  frame.scripts.OnUpdate(frame, 0.25)
  assert(ticks == 1)
  ticker:Cancel()
  frame.scripts.OnUpdate(frame, 1)
  assert(ticks == 1 and ticker:IsCancelled())

  timer.After(0, function()
    error("expected callback failure")
  end)
  timer.After(0, function()
    calls[#calls + 1] = "survived"
  end)
  frame.scripts.OnUpdate(frame, 0.01)
  assert(#errors == 1 and calls[#calls] == "survived", "one failed callback must not stop other timers")

  local repeats = 0
  timer.NewTicker(0.1, function()
    repeats = repeats + 1
  end, 2)
  frame.scripts.OnUpdate(frame, 1)
  assert(repeats == 1, "a slow frame must not create a catch-up loop")
  frame.scripts.OnUpdate(frame, 0.1)
  assert(repeats == 2 and not frame.shown)
end
