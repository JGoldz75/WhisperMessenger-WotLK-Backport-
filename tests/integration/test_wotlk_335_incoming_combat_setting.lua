-- Exercise the saved setting through the original client's complete event/UI
-- path. Preview popups remain independent of the main-window auto-open gate.
local Environment = require("tests.helpers.wotlk_environment")

local function copySaved(value)
  if type(value) ~= "table" then
    return value
  end
  local copy = {}
  for key, entry in pairs(value) do
    copy[key] = copySaved(entry)
  end
  return copy
end

local function startClient(savedSettings, savedAccount, savedCharacter)
  local env = Environment.Install()
  local inCombat = false
  _G.InCombatLockdown = function()
    return inCombat
  end
  _G.WhisperMessengerDB = savedAccount
    or {
      schemaVersion = 1,
      conversations = {},
      contacts = {},
      pendingHydration = {},
      settings = savedSettings,
    }
  _G.WhisperMessengerCharacterDB = savedCharacter
  local ns = {}
  for line in io.lines("WhisperMessenger.toc") do
    local path = line:match("^%s*(.-)%s*$")
    if path:match("%.lua$") then
      assert(loadfile((path:gsub("\\", "/"))))("WhisperMessenger", ns)
    end
  end
  local frame = assert(ns.Bootstrap._loadFrame)
  env.ui.Fire(frame, "OnEvent", "ADDON_LOADED", "WhisperMessenger")
  env.ui.Fire(frame, "OnEvent", "PLAYER_ENTERING_WORLD")
  local runtime = assert(ns.Bootstrap.runtime)
  function env.SetCombat(value)
    inCombat = value
    env.ui.Fire(frame, "OnEvent", value and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
  end
  function env.Receive(text, lineID)
    env.now = env.now + 1
    env.ui.Fire(frame, "OnEvent", "CHAT_MSG_WHISPER", text, "Jaina", "Common", "", "", "", 0, 0, "", 0, lineID, "0x0000000000000002")
    local key = assert(runtime.lastIncomingWhisperKey, "Incoming event must resolve a whisper conversation")
    return key, assert(runtime.store.conversations[key])
  end
  function env.Logout()
    env.ui.Fire(frame, "OnEvent", "PLAYER_LOGOUT")
  end
  return env, runtime
end

local function checkSetting(value, label)
  local settings = {
    autoOpenIncoming = true,
    autoOpenIncomingOutOfCombatOnly = value,
    showWidgetMessagePreview = true,
    widgetPreviewAutoDismissSeconds = 0,
  }
  local env, runtime = startClient(settings)
  assert(
    _G.WhisperMessengerDB.settings.autoOpenIncomingOutOfCombatOnly == value,
    label .. ": loading saved settings must preserve the explicit value"
  )
  assert(not runtime.isWindowVisible(), label .. ": initialization must not open the messenger")
  env.SetCombat(true)
  local key, conversation = env.Receive("Incoming during combat", 201)
  assert(
    #conversation.messages == 1 and conversation.messages[1].text == "Incoming during combat",
    label .. ": a blocked auto-open must never discard the message"
  )
  if value == false then
    assert(runtime.isWindowVisible(), "Explicit false must allow incoming whispers to open the main messenger in combat")
    assert(runtime.activeConversationKey == key, "An allowed auto-open must select the incoming whisper")
  else
    assert(not runtime.isWindowVisible(), label .. ": combat must block automatic main-window opening")
    assert(conversation.unreadCount == 1, label .. ": a blocked whisper must remain unread")
    assert(runtime.icon.previewFrame:IsShown(), label .. ": combat auto-open gate must not hide the preview popup")
    assert(runtime.icon.previewMessageLabel:GetText() == "Incoming during combat", label .. ": preview must still display the incoming message")
  end

  runtime.setWindowVisible(false)
  _G.SlashCmdList.WHISPERMESSENGER()
  assert(runtime.isWindowVisible(), label .. ": manual /wmsg must still open the messenger in combat")
  runtime.setWindowVisible(false)
  env.SetCombat(false)
  env.Receive("Incoming outside combat", 202)
  assert(runtime.isWindowVisible(), label .. ": incoming whispers must auto-open outside combat")
  assert(#conversation.messages == 2, label .. ": both messages must stay in history")

  -- The combat option does not enable auto-open by itself or change previews.
  runtime.setWindowVisible(false)
  settings.autoOpenIncoming = false
  env.SetCombat(true)
  env.Receive("Preview remains independent", 203)
  assert(not runtime.isWindowVisible(), label .. ": the master auto-open setting must still apply")
  assert(conversation.unreadCount == 1, label .. ": an unopened message must remain unread")
  assert(runtime.icon.previewFrame:IsShown(), label .. ": preview visibility must remain independent")
  assert(runtime.icon.previewMessageLabel:GetText() == "Preview remains independent")
  env.Logout()
  assert(_G.WhisperMessengerDB.settings.autoOpenIncomingOutOfCombatOnly == value, label .. ": logging out must preserve the combat preference")
  if value == false then
    -- Model a SavedVariables reload with fresh tables and a fresh namespace.
    local account = copySaved(_G.WhisperMessengerDB)
    local character = copySaved(_G.WhisperMessengerCharacterDB)
    account.settings.autoOpenIncoming = true
    local reloadedEnv, reloadedRuntime = startClient(nil, account, character)
    assert(reloadedRuntime.accountState.settings.autoOpenIncomingOutOfCombatOnly == false, "Explicit false must survive a full SavedVariables reload")
    reloadedEnv.now = 2000
    reloadedEnv.SetCombat(true)
    local _, reloadedConversation = reloadedEnv.Receive("Incoming after reload", 204)
    assert(reloadedRuntime.isWindowVisible(), "The saved false preference must still allow combat auto-open after reload")
    assert(#reloadedConversation.messages == 4, "Reloading must preserve the earlier whisper history")
  end
end

return function()
  assert(_VERSION == "Lua 5.1", "Original-Wrath integration tests require Lua 5.1")
  local savedRequire = _G.require
  _G.require = nil
  checkSetting(nil, "Existing saved settings")
  checkSetting(true, "Out-of-combat-only enabled")
  checkSetting(false, "Out-of-combat-only disabled")
  _G.require = savedRequire
end
