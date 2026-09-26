local Compat = require("WhisperMessenger.Core.FlavorCompat")
local Factory = require("WhisperMessenger.Core.Bootstrap.RuntimeFactory")
local Gateway = require("WhisperMessenger.Transport.ChatGateway")
local AddonComm = require("WhisperMessenger.Transport.AddonComm")

return function()
  Compat.isLegacyWrath = true
  _G.C_ChatInfo = nil
  _G.C_FriendList = nil
  local calls = {}
  _G.SendChatMessage = function(...)
    calls[#calls + 1] = { ... }
  end
  _G.SendAddonMessage = function(...)
    calls[#calls + 1] = { ... }
  end
  _G.GetRealmName = function()
    return "Frostmourne"
  end
  _G.GetNumFriends = function()
    return 2
  end
  _G.GetFriendInfo = function(index)
    if index == 1 then
      return "Alice", 80, "Mage", "Dalaran", 1, "<AFK>", "Friend note"
    end
    if index == 2 then
      return "Bob", 70, "Warrior", "Unknown", nil, "", ""
    end
  end
  _G.GetPlayerInfoByGUID = function(guid)
    if guid == "0x0000000000000001" then
      return "Mage", "MAGE", "Human", "Human", 2, "Alice", ""
    end
    return nil
  end
  local partyCount, raidCount, instanceType = 0, 0, "none"
  _G.GetNumPartyMembers = function()
    return partyCount
  end
  _G.GetNumRaidMembers = function()
    return raidCount
  end
  _G.IsInInstance = function()
    return instanceType ~= "none", instanceType
  end

  -- Runtime must expose usable adapters without any C_* APIs installed.
  local runtime = Factory.CreateRuntimeState({ settings = {} }, {}, "me", {
    now = function()
      return 1
    end,
  })
  assert(type(runtime.chatApi.SendAddonMessage) == "function", "legacy runtime needs an addon-message sender")
  assert(runtime.friendListApi.GetFriendInfo("Alice").connected == true, "legacy online flags may be numeric")
  assert(runtime.friendListApi.GetFriendInfo("Bob").connected == false, "offline friend nil becomes false")
  assert(runtime.friendListApi.GetFriendInfo("alice-Frostmourne").name == "Alice", "friend lookup accepts local realm suffix")
  assert(runtime.friendListApi.GetFriendInfo("Alice-OtherRealm") == nil, "foreign realm must not match a local friend")
  assert(runtime.friendListApi.IsFriend("0x0000000000000001") == true, "friend checks resolve cached player GUIDs")
  assert(runtime.friendListApi.IsFriend("0x0000000000000002") == false, "unknown GUID is not a known friend")

  Gateway.Send(runtime.chatApi, { channel = "WHISPER", target = "Alice-Frostmourne" }, "hello")
  assert(calls[#calls][2] == "WHISPER" and calls[#calls][4] == "Alice", "legacy whispers use the local character name")
  Gateway.SendGuild(runtime.chatApi, "guild hello")
  assert(calls[#calls][2] == "GUILD", "legacy guild messages use SendChatMessage")
  assert(AddonComm.RegisterPrefix(runtime.chatApi, "WMRX"), "Wrath addon messages require no prefix registration")
  assert(AddonComm.Send(runtime.chatApi, "WMRX", "payload", "Alice-Frostmourne"), "legacy addon whisper sends")
  assert(calls[#calls][4] == "Alice", "addon whispers normalize local realm suffix")
  assert(AddonComm.Send(runtime.chatApi, "WMRX", string.rep("x", 250), "Alice"), "254 bytes of prefix and payload fit")
  assert(not AddonComm.Send(runtime.chatApi, "WMRX", string.rep("x", 251), "Alice"), "legacy packet length includes its prefix")

  assert(not Gateway.CanSend(runtime.chatApi, { channel = "PARTY" }), "solo players cannot send party messages")
  partyCount = 2
  assert(Compat.GetNumGroupMembers() == 3, "party count includes the local player")
  assert(Gateway.CanSend(runtime.chatApi, { channel = "PARTY" }), "party players can send party messages")
  raidCount = 10
  assert(Compat.GetNumGroupMembers() == 10, "raid count already includes the local player")
  assert(Gateway.CanSend(runtime.chatApi, { channel = "RAID" }), "raid players can send raid messages")
  instanceType = "pvp"
  assert(Gateway.CanSend(runtime.chatApi, { channel = "INSTANCE_CHAT" }), "battleground uses the instance conversation")
  Gateway.SendInstance(runtime.chatApi, "battleground hello")
  assert(calls[#calls][2] == "BATTLEGROUND", "Wrath battleground uses BATTLEGROUND chat")
  assert(AddonComm.SendGroup(runtime.chatApi, "WMRX", "payload", "INSTANCE_CHAT"), "battleground addon packets send")
  assert(calls[#calls][3] == "BATTLEGROUND", "addon battleground channel is normalized")
  instanceType = "party"
  assert(not Gateway.CanSend(runtime.chatApi, { channel = "INSTANCE_CHAT" }), "Wrath dungeon chat remains PARTY")
end
