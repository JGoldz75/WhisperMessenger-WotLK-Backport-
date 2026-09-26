local Compat = require("WhisperMessenger.Core.FlavorCompat")
local Presence = require("WhisperMessenger.Model.PresenceCache")
local RosterLookup = require("WhisperMessenger.Model.RosterLookup")
local Enricher = require("WhisperMessenger.Model.ContactEnricher.AvailabilityEnricher")

return function()
  Compat.isLegacyWrath = true
  _G.GetRealmName = function()
    return "Frostmourne"
  end
  _G.GetNumPartyMembers = function()
    return 1
  end
  _G.GetNumRaidMembers = function()
    return 0
  end
  _G.UnitName = function(unit)
    if unit == "party1" then
      return "Alice"
    end
  end
  _G.UnitGUID = function(unit)
    if unit == "party1" then
      return "0x0000000000000001"
    end
  end
  _G.GetPlayerInfoByGUID = function(guid)
    if guid == "0x0000000000000001" then
      return "Mage", "MAGE", "Human", "Human", 2, "Alice", ""
    end
    if guid == "0x0000000000000002" then
      return "Warrior", "WARRIOR", "Human", "Human", 2, "Bob", ""
    end
  end
  _G.GetNumFriends = function()
    return 0
  end
  local online, reads = true, 0
  _G.GetNumGuildMembers = function()
    return 2
  end
  _G.GetGuildRosterInfo = function(index)
    reads = reads + 1
    if index == 1 then
      return "Alice", "Member", 2, 80, "Mage", "Dalaran", "", "", online
    end
    return "Bob", "Member", 2, 80, "Warrior", "Unknown", "", "", nil
  end
  assert(RosterLookup.FindGUIDByName(nil, "Alice-Frostmourne") == "0x0000000000000001", "legacy roster resolves group GUIDs")
  assert(RosterLookup.FindGUIDByName(nil, "Alice-OtherRealm") == nil, "legacy roster never confuses a foreign realm")

  local now = 100
  Presence.Initialize(nil, {
    now = function()
      return now
    end,
  })
  assert(Presence.EnsureFresh("0x0000000000000001") == "online", "legacy guild online flag provides presence")
  assert(Presence.GetZone("0x0000000000000001") == "Dalaran", "legacy guild roster provides zone")
  assert(Presence.EnsureFresh("0x0000000000000002") == "offline", "legacy guild offline flag provides presence")
  local initialReads = reads
  Presence.EnsureFresh("0x0000000000000001")
  assert(reads == initialReads, "legacy presence uses the existing TTL")
  now = 131
  online = false
  assert(Presence.EnsureFresh("0x0000000000000001") == "offline", "legacy presence refresh observes an offline transition")
  assert(Presence.GetZone("0x0000000000000001") == nil, "offline characters do not retain a live zone")
  assert(Presence.EnsureFresh("0x0000000000000003") == nil, "unknown players do not become falsely offline")

  local contacts = { { channel = "WOW", guid = "0x0000000000000003", displayName = "Stranger" } }
  Enricher.EnrichContactsAvailability(contacts, { availabilityByGUID = {}, sendStatusByConversation = {} })
  assert(contacts[1].availability == nil, "unknown legacy availability stays unknown")

  contacts = { { channel = "WOW", guid = "0x0000000000000001", displayName = "Alice" } }
  local runtime = { availabilityByGUID = { ["0x0000000000000001"] = { status = "CanWhisper", canWhisper = true } } }
  Enricher.EnrichContactsAvailability(contacts, runtime)
  assert(contacts[1].availability.status == "Offline", "fresh roster offline state overrides an old successful whisper")
  online = true
  Presence.Invalidate()
  assert(Presence.EnsureFresh("0x0000000000000001") == "online", "roster invalidation refreshes legacy presence immediately")
end
