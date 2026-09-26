local EventBridge = require("WhisperMessenger.Core.Bootstrap.EventBridge")
local AutoOpenHooks = require("WhisperMessenger.Core.Bootstrap.AutoOpenHooks")

local function routeWhisper(outOfCombatOnly, inCombat, autoOpenIncoming)
  local settings = {
    autoOpenIncoming = autoOpenIncoming,
    autoOpenIncomingOutOfCombatOnly = outOfCombatOnly,
    playSoundOnWhisper = false,
    flashTaskbarOnWhisper = false,
  }
  local opened = 0
  local runtime = {
    store = { conversations = {}, config = {} },
    localProfileId = "me",
    now = function()
      return 100
    end,
    accountState = { settings = settings },
    availabilityByGUID = {},
    pendingOutgoing = {},
    onAutoOpen = function()
      opened = opened + 1
    end,
  }
  local previousCombatCheck = _G.InCombatLockdown
  rawset(_G, "InCombatLockdown", function()
    -- Original-client combat APIs can return 1/nil instead of true/false.
    return inCombat and 1 or nil
  end)
  local conversation = EventBridge.RouteLiveEvent(runtime, nil, "CHAT_MSG_WHISPER", "hello", "Arthas")
  rawset(_G, "InCombatLockdown", previousCombatCheck)
  assert(conversation and #conversation.messages == 1, "combat settings must not discard incoming messages")
  assert(conversation.unreadCount == 1, "a blocked auto-open must still count the message as unread")
  assert(runtime.lastIncomingWhisperKey == conversation.conversationKey, "the reply target must still be recorded")
  return opened
end

local function incomingHook(outOfCombatOnly, inCombat)
  local opened = 0
  local focused = 0
  local hooks = AutoOpenHooks.Create({
    getSettings = function()
      return { autoOpenIncoming = true, autoOpenIncomingOutOfCombatOnly = outOfCombatOnly }
    end,
    isInCombat = function()
      return inCombat
    end,
    isWindowVisible = function()
      return false
    end,
    ensureWindow = function()
      opened = opened + 1
    end,
    setWindowVisible = function() end,
    selectConversation = function() end,
    focusComposer = function()
      focused = focused + 1
    end,
  })
  hooks.onIncomingWhisper("wow::arthas")
  assert(focused == 0, "incoming auto-open must not request input focus")
  return opened
end

return function()
  assert(routeWhisper(false, true, true) == 1, "turning off the combat-only option should allow incoming auto-open during combat")
  assert(routeWhisper(true, true, true) == 0, "the enabled option should prevent incoming auto-open during combat")
  assert(routeWhisper(nil, true, true) == 0, "existing settings should keep combat protection by default")
  assert(routeWhisper(true, false, true) == 1, "incoming whispers should open the window outside combat")
  assert(routeWhisper(false, false, true) == 1, "turning off combat protection should also allow opening outside combat")
  assert(routeWhisper(false, true, false) == 0, "the master incoming auto-open toggle must still be respected")
  assert(routeWhisper(true, false, false) == 0, "the combat option must not enable auto-open by itself")

  assert(incomingHook(true, true) == 0, "the incoming hook must enforce the combat option even when called directly")
  assert(incomingHook(nil, true) == 0, "the incoming hook must preserve combat protection for existing settings")
  assert(incomingHook(false, true) == 1, "the incoming hook must honor disabled combat protection")
  assert(incomingHook(true, false) == 1, "the incoming hook must still open outside combat")
end
