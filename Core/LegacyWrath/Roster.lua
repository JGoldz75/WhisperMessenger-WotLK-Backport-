local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Chat = ns.LegacyWrathChat or require("WhisperMessenger.Core.LegacyWrath.Chat")
local Roster = {}

local function canonical(name)
  return type(name) == "string" and string.lower(Chat.LocalName(name)) or nil
end

local function matchUnit(unit, target)
  local name, realm = _G.UnitName(unit)
  if name and realm and realm ~= "" then
    name = name .. "-" .. realm
  end
  if canonical(name) == target then
    return _G.UnitGUID(unit)
  end
end

function Roster.FindGUIDByName(name)
  local target = canonical(name)
  if target == nil or type(_G.UnitName) ~= "function" or type(_G.UnitGUID) ~= "function" then
    return nil
  end
  for _, unit in ipairs({ "player", "target", "focus", "mouseover" }) do
    local guid = matchUnit(unit, target)
    if guid then
      return guid
    end
  end
  local raid = type(_G.GetNumRaidMembers) == "function" and _G.GetNumRaidMembers() or 0
  local party = type(_G.GetNumPartyMembers) == "function" and _G.GetNumPartyMembers() or 0
  local prefix, count = "party", party
  if raid > 0 then
    prefix, count = "raid", raid
  end
  for index = 1, count do
    local guid = matchUnit(prefix .. index, target)
    if guid then
      return guid
    end
  end
  -- 3.3.5's guild/friend tuples contain no GUID. Never invent one.
  return nil
end

local function nameByGUID(guid)
  if type(_G.GetPlayerInfoByGUID) ~= "function" then
    return nil
  end
  local _, _, _, _, _, name, realm = _G.GetPlayerInfoByGUID(guid)
  if name and realm and realm ~= "" then
    name = name .. "-" .. realm
  end
  return Chat.LocalName(name)
end

local function presenceAndZone(online, zone)
  if online and online ~= 0 then
    return "online", type(zone) == "string" and zone ~= "" and zone or nil
  end
  return "offline", nil
end

function Roster.ReadPresence(guid)
  local name = nameByGUID(guid)
  local target = canonical(name)
  if target == nil then
    return nil
  end
  local friend = Chat.GetFriendListApi().GetFriendInfo(name)
  if friend then
    return presenceAndZone(friend.connected, friend.area)
  end
  if type(_G.GetNumGuildMembers) == "function" and type(_G.GetGuildRosterInfo) == "function" then
    for index = 1, _G.GetNumGuildMembers(true) or 0 do
      local memberName, _, _, _, _, zone, _, _, online = _G.GetGuildRosterInfo(index)
      if canonical(memberName) == target then
        return presenceAndZone(online, zone)
      end
    end
  end
  return nil
end

ns.LegacyWrathRoster = Roster
return Roster
