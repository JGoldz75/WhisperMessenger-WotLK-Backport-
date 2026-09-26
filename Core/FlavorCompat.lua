local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local FlavorCompat = {}

local projectId = _G["WOW_PROJECT_ID"]
local MAINLINE = _G["WOW_PROJECT_MAINLINE"] or 1

FlavorCompat.isRetail = (projectId == MAINLINE)
FlavorCompat.isClassic = not FlavorCompat.isRetail

-- ponytail: no WOW_PROJECT_FOREVER exists; GetBuildInfo toc 16xxx is the only signal
local FOREVER_TOC_MIN = 16000
local FOREVER_TOC_MAX = 17000
local tocVersion = nil
if type(_G["GetBuildInfo"]) == "function" then
  tocVersion = select(4, _G["GetBuildInfo"]())
end
FlavorCompat.isForever = type(tocVersion) == "number" and tocVersion >= FOREVER_TOC_MIN and tocVersion < FOREVER_TOC_MAX
FlavorCompat.isLegacyWrath = tocVersion == 30300

local legacyTimer
function FlavorCompat.GetTimer()
  if type(_G.C_Timer) == "table" then
    return _G.C_Timer
  end
  if not FlavorCompat.isLegacyWrath or type(_G.CreateFrame) ~= "function" then
    return nil
  end
  if not legacyTimer then
    local Timer = ns.LegacyWrathTimer or require("WhisperMessenger.Core.LegacyWrath.Timer")
    legacyTimer = Timer.New(_G.CreateFrame, function(err)
      if type(_G.geterrorhandler) == "function" then
        _G.geterrorhandler()(err)
      end
    end)
  end
  return legacyTimer
end

-- Feature flags — true only on flavors that support the feature
FlavorCompat.hasMythicPlus = FlavorCompat.isRetail and not FlavorCompat.isForever

ns.FlavorCompat = FlavorCompat

return FlavorCompat
