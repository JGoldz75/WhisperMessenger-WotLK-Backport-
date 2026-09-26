local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Compat = ns.FlavorCompat or require("WhisperMessenger.Core.FlavorCompat")
local Events = {}

-- Only subscribe to events used by this addon and present in build 12340.
-- This also avoids relying on the wording of client RegisterEvent errors.
local supported = {
  CHAT_MSG_WHISPER = true,
  CHAT_MSG_WHISPER_INFORM = true,
  CHAT_MSG_AFK = true,
  CHAT_MSG_DND = true,
  CHAT_MSG_ADDON = true,
  CHAT_MSG_SYSTEM = true,
  CHAT_MSG_CHANNEL = true,
  CHAT_MSG_PARTY = true,
  CHAT_MSG_PARTY_LEADER = true,
  CHAT_MSG_RAID = true,
  CHAT_MSG_RAID_LEADER = true,
  CHAT_MSG_RAID_WARNING = true,
  CHAT_MSG_GUILD = true,
  CHAT_MSG_OFFICER = true,
  CHAT_MSG_BATTLEGROUND = true,
  CHAT_MSG_BATTLEGROUND_LEADER = true,
  FRIENDLIST_UPDATE = true,
  PLAYER_ENTERING_WORLD = true,
  PLAYER_LOGOUT = true,
  GUILD_ROSTER_UPDATE = true,
  PARTY_MEMBERS_CHANGED = true,
  RAID_ROSTER_UPDATE = true,
  PLAYER_REGEN_DISABLED = true,
  PLAYER_REGEN_ENABLED = true,
  ZONE_CHANGED_NEW_AREA = true,
  UPDATE_BINDINGS = true,
}

local aliases = {
  GROUP_ROSTER_UPDATE = { "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE" },
  CHAT_MSG_INSTANCE_CHAT = { "CHAT_MSG_BATTLEGROUND" },
  CHAT_MSG_INSTANCE_CHAT_LEADER = { "CHAT_MSG_BATTLEGROUND_LEADER" },
}

function Events.ResolveNames(eventName)
  if not Compat.isLegacyWrath then
    return { eventName }
  end
  if aliases[eventName] then
    return aliases[eventName]
  end
  return supported[eventName] and { eventName } or {}
end

function Events.NormalizeGroupEvent(eventName)
  if Compat.isLegacyWrath then
    if eventName == "CHAT_MSG_BATTLEGROUND" then
      return "CHAT_MSG_INSTANCE_CHAT"
    elseif eventName == "CHAT_MSG_BATTLEGROUND_LEADER" then
      return "CHAT_MSG_INSTANCE_CHAT_LEADER"
    end
  end
  return eventName
end

function Events.NormalizeChannel(channel)
  return Compat.isLegacyWrath and channel == "BATTLEGROUND" and "INSTANCE_CHAT" or channel
end

ns.LegacyWrathEvents = Events
return Events
