local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

-- Private timer queue for the original client. Never replace another addon's C_Timer.
local Timer = {}

function Timer.New(createFrame, onError)
  local frame
  local queue = {}
  local clock = 0
  local api = {}

  local function onUpdate(_, elapsed)
    clock = clock + elapsed
    local pending = queue
    queue = {}
    for _, item in ipairs(pending) do
      if not item.cancelled then
        if item.due <= clock then
          local ok, err = pcall(item.callback, item)
          if not ok and onError then
            pcall(onError, err)
          end
          if item.remaining then
            item.remaining = item.remaining - 1
          end
          if item.interval and not item.cancelled and (not item.remaining or item.remaining > 0) then
            item.due = clock + item.interval
            queue[#queue + 1] = item
          end
        else
          queue[#queue + 1] = item
        end
      end
    end
    if #queue == 0 then
      frame:Hide()
    end
  end

  local function schedule(delay, callback, repeating, iterations)
    assert(type(callback) == "function", "timer callback must be a function")
    delay = math.max(0, tonumber(delay) or 0)
    local item = {
      due = clock + delay,
      callback = callback,
      interval = repeating and math.max(0.01, delay) or nil,
      remaining = iterations,
    }
    function item:Cancel()
      self.cancelled = true
    end
    function item:IsCancelled()
      return self.cancelled == true
    end
    if not frame then
      frame = createFrame("Frame")
      frame:SetScript("OnUpdate", onUpdate)
    end
    queue[#queue + 1] = item
    frame:Show()
    return item
  end

  function api.After(delay, callback)
    schedule(delay, function()
      callback()
    end)
  end
  function api.NewTimer(delay, callback)
    return schedule(delay, callback)
  end
  function api.NewTicker(delay, callback, iterations)
    return schedule(delay, callback, true, iterations)
  end
  return api
end

ns.LegacyWrathTimer = Timer
return Timer
