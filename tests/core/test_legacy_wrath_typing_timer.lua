local Compat = require("WhisperMessenger.Core.FlavorCompat")
local EventBridge = require("WhisperMessenger.Core.Bootstrap.EventBridge")
local Store = require("WhisperMessenger.Model.ConversationStore")

return function()
  local callback
  _G.C_Timer = nil
  Compat.GetTimer = function()
    return {
      After = function(_, fn)
        callback = fn
      end,
    }
  end
  local now = 100
  local key = "wow::WOW::alice"
  local runtime = {
    localProfileId = "me",
    store = Store.New({}),
    accountState = { settings = {} },
    availabilityByGUID = {},
    pendingOutgoing = {},
    now = function()
      return now
    end,
  }
  runtime.store.conversations[key] = { channel = "WOW", displayName = "Alice", messages = {} }
  local refreshed = 0
  EventBridge.RouteLiveEvent(runtime, function()
    refreshed = refreshed + 1
  end, "CHAT_MSG_ADDON", "WMRX", "1|T|1", "WHISPER", "Alice")
  assert(type(callback) == "function", "typing expiry uses the addon-local timer on Wrath")
  now = 108
  callback()
  assert(refreshed == 2, "typing expiry redraws the conversation once")
  assert(runtime.typingByConversation[key] == nil, "expired typing state is cleared")
end
