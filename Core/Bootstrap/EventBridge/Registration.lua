local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Constants = ns.Constants or require("WhisperMessenger.Core.Constants")
local EventUtils = ns.EventUtils or require("WhisperMessenger.Core.EventUtils")
local LegacyEvents = ns.LegacyWrathEvents or require("WhisperMessenger.Core.LegacyWrath.Events")

local Registration = {}

local function registerEventIfSupported(frame, eventName)
  return EventUtils.RegisterEventIfSupported(frame, eventName)
end

local function unregisterEventIfSupported(frame, eventName)
  for _, name in ipairs(LegacyEvents.ResolveNames(eventName)) do
    local ok, err = pcall(frame.UnregisterEvent, frame, name)
    if not ok and not EventUtils.IsUnknownEventError(err) then
      error(err)
    end
  end
end

function Registration.RegisterLiveEvents(frame)
  for _, eventName in ipairs(Constants.LIVE_EVENT_NAMES) do
    registerEventIfSupported(frame, eventName)
  end
end

function Registration.UnregisterLiveEvents(frame)
  for _, eventName in ipairs(Constants.LIVE_EVENT_NAMES) do
    if frame.UnregisterEvent then
      unregisterEventIfSupported(frame, eventName)
    end
  end
end

function Registration.RegisterChannelEvents(frame)
  for _, eventName in ipairs(Constants.CHANNEL_EVENT_NAMES) do
    registerEventIfSupported(frame, eventName)
  end
end

function Registration.RegisterGroupEvents(frame)
  for _, eventName in ipairs(Constants.GROUP_EVENT_NAMES) do
    registerEventIfSupported(frame, eventName)
  end
end

function Registration.RegisterSuspendableLifecycleEvents(frame)
  local essential = Constants.MYTHIC_ESSENTIAL_EVENTS or {}
  for _, eventName in ipairs(Constants.LIFECYCLE_EVENT_NAMES) do
    if not essential[eventName] then
      registerEventIfSupported(frame, eventName)
    end
  end
end

function Registration.UnregisterSuspendableLifecycleEvents(frame)
  local essential = Constants.MYTHIC_ESSENTIAL_EVENTS or {}
  for _, eventName in ipairs(Constants.LIFECYCLE_EVENT_NAMES) do
    if not essential[eventName] and frame.UnregisterEvent then
      unregisterEventIfSupported(frame, eventName)
    end
  end
end

ns.BootstrapEventBridgeRegistration = Registration

return Registration
