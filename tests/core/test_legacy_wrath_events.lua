local Compat = require("WhisperMessenger.Core.FlavorCompat")
local EventBridge = require("WhisperMessenger.Core.Bootstrap.EventBridge")
local EventUtils = require("WhisperMessenger.Core.EventUtils")
local Constants = require("WhisperMessenger.Core.Constants")
local Lifecycle = require("WhisperMessenger.Core.Bootstrap.LifecycleHandlers")
local Store = require("WhisperMessenger.Model.ConversationStore")
local LivePayload = require("WhisperMessenger.Core.Bootstrap.EventBridge.LivePayload")

return function()
  Compat.isLegacyWrath = true
  local events = {}
  local frame = {
    RegisterEvent = function(_, event)
      events[event] = true
    end,
    UnregisterEvent = function(_, event)
      events[event] = nil
    end,
  }
  EventBridge.RegisterLiveEvents(frame)
  EventBridge.RegisterGroupEvents(frame)
  for _, event in ipairs(Constants.LIFECYCLE_EVENT_NAMES) do
    EventUtils.RegisterEventIfSupported(frame, event)
  end
  assert(events.CHAT_MSG_WHISPER, "registers the original whisper event")
  assert(events.PARTY_MEMBERS_CHANGED, "registers the original party roster event")
  assert(events.RAID_ROSTER_UPDATE, "registers the original raid roster event")
  assert(events.CHAT_MSG_BATTLEGROUND, "registers the original battleground chat event")
  assert(events.CHAT_MSG_BATTLEGROUND_LEADER, "registers the original battleground leader event")
  assert(not events.GROUP_ROSTER_UPDATE and not events.CLUB_MEMBER_UPDATED, "does not register unavailable roster events")
  assert(not events.CAN_LOCAL_WHISPER_TARGET_RESPONSE, "does not register unavailable whisper availability events")
  assert(not events.CHAT_MSG_INSTANCE_CHAT and not events.CHAT_MSG_COMMUNITIES_CHANNEL, "does not register modern group events")
  assert(not events.CHAT_MSG_BN_WHISPER, "legacy private servers do not expose Battle.net account chat")

  _G.GetNumPartyMembers = function()
    return 0
  end
  _G.GetNumRaidMembers = function()
    return 0
  end
  local conversations = { ["party::me"] = { channel = "PARTY", messages = {} } }
  local bootstrap = { runtime = { localProfileId = "me", accountState = { conversations = conversations } } }
  assert(Lifecycle.Handle(bootstrap, "PARTY_MEMBERS_CHANGED", {}), "routes original party roster changes")
  assert(conversations["party::me"].leftGroup, "leaving an original party closes its conversation")
  local invalidated = false
  Lifecycle.Handle(bootstrap, "FRIENDLIST_UPDATE", {
    getPresenceCache = function()
      return {
        Invalidate = function()
          invalidated = true
        end,
      }
    end,
  })
  assert(invalidated, "legacy friend events invalidate the roster presence cache")

  _G.date = os.date
  local runtime = {
    localProfileId = "me",
    localPlayerGuid = "0x0000000000000001",
    now = function()
      return 100
    end,
    accountState = { settings = {} },
    store = Store.New({}, function()
      return 100
    end),
  }
  assert(
    EventBridge.RouteGroupEvent(runtime, "CHAT_MSG_BATTLEGROUND", "hi", "Alice", nil, nil, nil, nil, nil, nil, nil, nil, 22, "0x0000000000000002"),
    "ingests the original battleground event"
  )
  local conversation = runtime.store.conversations["instance::me"]
  assert(conversation and conversation.channel == "INSTANCE_CHAT", "battleground history uses an instance conversation")
  assert(conversation.messages[1].text == "hi", "captures battleground text")
  local payload = LivePayload.Build(runtime, "CHAT_MSG_ADDON", "WMRX", "payload", "BATTLEGROUND", "Alice")
  assert(payload.channel == "INSTANCE_CHAT", "battleground addon packets use the same conversation channel")

  EventBridge.UnregisterSuspendableLifecycleEvents(frame)
  assert(not events.PARTY_MEMBERS_CHANGED and not events.RAID_ROSTER_UPDATE, "unregisters both original roster events")
  assert(events.PLAYER_ENTERING_WORLD, "essential lifecycle events remain registered")
end
