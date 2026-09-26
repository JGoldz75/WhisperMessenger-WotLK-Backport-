local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Compat = ns.FlavorCompat or require("WhisperMessenger.Core.FlavorCompat")
local Chat = {}

local function normalizedRealm(value)
  return string.lower((value or ""):gsub("%s", ""))
end

function Chat.LocalName(name)
  if type(name) ~= "string" then
    return name
  end
  local character, realm = string.match(name, "^([^%-]+)%-(.+)$")
  if character and type(_G.GetRealmName) == "function" and normalizedRealm(realm) == normalizedRealm(_G.GetRealmName()) then
    return character
  end
  return name
end

local function wireChannel(channel)
  return channel == "INSTANCE_CHAT" and "BATTLEGROUND" or channel
end

local legacyChatApi = {
  RegisterAddonMessagePrefix = function(prefix)
    -- 3.3.5 receives all prefixes. Registration was introduced in Cataclysm.
    return type(_G.SendAddonMessage) == "function" and type(prefix) == "string" and prefix ~= ""
  end,
  SendChatMessage = function(text, channel, language, target)
    return _G.SendChatMessage(text, wireChannel(channel), language, Chat.LocalName(target))
  end,
  SendAddonMessage = function(prefix, text, channel, target)
    -- The original client counts the prefix and separator in the 255-byte
    -- packet limit. Never let the client truncate a protocol packet.
    if #prefix + #text > 254 then
      return false
    end
    return _G.SendAddonMessage(prefix, text, wireChannel(channel), Chat.LocalName(target))
  end,
}

function Chat.GetChatApi()
  if Compat.isLegacyWrath then
    return legacyChatApi
  end
  return _G.C_ChatInfo or {}
end

local function friendAt(index)
  if type(_G.GetFriendInfo) ~= "function" then
    return nil
  end
  local name, level, className, area, connected, status, notes = _G.GetFriendInfo(index)
  if not name then
    return nil
  end
  return {
    name = name,
    level = level,
    className = className,
    area = area,
    connected = connected and connected ~= 0 and true or false,
    status = status,
    notes = notes,
  }
end

local function friendInfo(nameOrIndex)
  if type(nameOrIndex) == "number" then
    return friendAt(nameOrIndex)
  end
  if type(nameOrIndex) ~= "string" or type(_G.GetNumFriends) ~= "function" then
    return nil
  end
  local wanted = string.lower(Chat.LocalName(nameOrIndex))
  for index = 1, _G.GetNumFriends() or 0 do
    local info = friendAt(index)
    if info and string.lower(Chat.LocalName(info.name)) == wanted then
      return info
    end
  end
  return nil
end

local legacyFriendApi = {
  GetFriendInfo = friendInfo,
  GetFriendInfoByIndex = friendAt,
  GetNumFriends = function()
    return type(_G.GetNumFriends) == "function" and _G.GetNumFriends() or 0
  end,
  IsFriend = function(guid)
    if type(_G.GetPlayerInfoByGUID) ~= "function" or type(guid) ~= "string" then
      return false
    end
    local _, _, _, _, _, name, realm = _G.GetPlayerInfoByGUID(guid)
    if name and realm and realm ~= "" then
      name = name .. "-" .. realm
    end
    return friendInfo(name) ~= nil
  end,
}

function Chat.GetFriendListApi()
  if Compat.isLegacyWrath then
    return legacyFriendApi
  end
  return _G.C_FriendList or {}
end

local function legacyCount(fn)
  if type(fn) ~= "function" then
    return 0
  end
  return tonumber(fn()) or 0
end

function Chat.IsInBattleground()
  if type(_G.IsInInstance) ~= "function" then
    return false
  end
  local _, instanceType = _G.IsInInstance()
  return instanceType == "pvp" or instanceType == "arena"
end

function Chat.IsInGroup(category)
  if not Compat.isLegacyWrath then
    return type(_G.IsInGroup) == "function" and _G.IsInGroup(category) or false
  end
  local inGroup = legacyCount(_G.GetNumRaidMembers) > 0 or legacyCount(_G.GetNumPartyMembers) > 0
  if category == 2 then
    return inGroup and Chat.IsInBattleground()
  end
  if category == 1 then
    return inGroup and not Chat.IsInBattleground()
  end
  return inGroup
end

function Chat.IsInRaid(category)
  if not Compat.isLegacyWrath then
    return type(_G.IsInRaid) == "function" and _G.IsInRaid(category) or false
  end
  local inRaid = legacyCount(_G.GetNumRaidMembers) > 0
  if category == 1 then
    return inRaid and not Chat.IsInBattleground()
  end
  return inRaid
end

function Chat.GetNumGroupMembers()
  if not Compat.isLegacyWrath then
    return type(_G.GetNumGroupMembers) == "function" and _G.GetNumGroupMembers() or 0
  end
  local raid = legacyCount(_G.GetNumRaidMembers)
  if raid > 0 then
    return raid
  end
  local party = legacyCount(_G.GetNumPartyMembers)
  return party > 0 and party + 1 or 0
end

Compat.GetChatApi = Chat.GetChatApi
Compat.GetFriendListApi = Chat.GetFriendListApi
Compat.IsInGroup = Chat.IsInGroup
Compat.IsInRaid = Chat.IsInRaid
Compat.GetNumGroupMembers = Chat.GetNumGroupMembers
ns.LegacyWrathChat = Chat
return Chat
