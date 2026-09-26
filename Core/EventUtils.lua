local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local LegacyEvents = ns.LegacyWrathEvents or require("WhisperMessenger.Core.LegacyWrath.Events")
local EventUtils = {}

-- RegisterEvent throws "Attempt to register unknown event ..." on clients that
-- lack a given event (e.g. ADDON_RESTRICTION_STATE_CHANGED pre-12.0, or
-- CLUB_MEMBER_UPDATED on minimal Classic flavors). Detect those so callers can
-- skip silently while re-raising every other failure.
function EventUtils.IsUnknownEventError(err)
  return string.find(string.lower(tostring(err or "")), "unknown event", 1, true) ~= nil
end

function EventUtils.RegisterEventIfSupported(frame, eventName)
  local registered = false
  for _, name in ipairs(LegacyEvents.ResolveNames(eventName)) do
    local ok, err = pcall(frame.RegisterEvent, frame, name)
    if ok then
      registered = true
    elseif not EventUtils.IsUnknownEventError(err) then
      error(err)
    end
  end
  return registered
end

ns.EventUtils = EventUtils

return EventUtils
