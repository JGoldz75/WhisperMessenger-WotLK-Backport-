-- Run on real Lua 5.1. This models the original 12340 client, not Wrath Classic.
local Environment = require("tests.helpers.wotlk_environment")

local function chat(env, frame, event, text, sender, lineID, guid)
  assert(frame:IsEventRegistered(event), "The addon did not subscribe to " .. event)
  env.ui.Fire(frame, "OnEvent", event, text, sender, "Common", "", "", "", 0, 0, "", 0, lineID, guid)
end

local function findConversation(runtime, channel)
  for key, conversation in pairs(runtime.store.conversations) do
    if conversation.channel == channel then
      return key, conversation
    end
  end
end

local function send(env, window, text)
  window.composer.input:SetText(text)
  env.ui.Fire(window.composer.input, "OnTextChanged", true)
  env.ui.Fire(window.composer.input, "OnEnterPressed")
end

return function()
  assert(_VERSION == "Lua 5.1", "The 3.3.5 smoke test must run under Lua 5.1")
  local env = Environment.Install()
  local probe = env.ui.CreateFrame("Frame")
  assert(
    probe.SetColorTexture == nil and probe.SetShown == nil and probe.SetResizeBounds == nil,
    "The strict harness must not provide modern widget methods"
  )
  local legacyFactory = _G.CreateFrame
  local savedRequire = _G.require
  _G.require = nil -- WoW loads the TOC with an addon-private namespace.
  local ns = {}
  for line in io.lines("WhisperMessenger.toc") do
    local path = line:match("^%s*(.-)%s*$")
    if path ~= "" and path:sub(1, 1) ~= "#" and path:match("%.lua$") then
      local chunk = assert(loadfile(path:gsub("\\", "/")))
      local ok, err = pcall(chunk, "WhisperMessenger", ns)
      assert(ok, path .. ": " .. tostring(err))
    end
  end
  local loadFrame = assert(ns.Bootstrap._loadFrame)
  env.ui.Fire(loadFrame, "OnEvent", "ADDON_LOADED", "WhisperMessenger")
  local runtime = assert(ns.Bootstrap.runtime, "ADDON_LOADED did not initialize")
  assert(runtime.localProfileId == "tester-frostmourne", runtime.localProfileId)
  assert(loadFrame:IsEventRegistered("PARTY_MEMBERS_CHANGED"), "Legacy party-roster event must be registered")
  assert(loadFrame:IsEventRegistered("RAID_ROSTER_UPDATE"), "Legacy raid-roster event must be registered")
  env.ui.Fire(loadFrame, "OnEvent", "PLAYER_LOGIN")
  env.ui.Fire(loadFrame, "OnEvent", "PLAYER_ENTERING_WORLD")
  runtime.toggle()
  assert(runtime.window and runtime.window.frame:IsShown(), "Window should open on /wm")
  env.Advance(1)
  local window = runtime.window

  runtime.accountState.settings.playSoundOnWhisper = true
  chat(env, loadFrame, "CHAT_MSG_WHISPER", "Hello from Wrath", "Jaina", 101, "0x0000000000000002")
  local whisperKey, whisper = findConversation(runtime, "WOW")
  assert(whisperKey and #whisper.messages == 1, "Incoming character whisper must be stored")
  assert(whisper.messages[1].text == "Hello from Wrath")
  assert(#env.sounds > 0, "Incoming-whisper sound must use a legacy sound name")
  assert(window.selectConversation(whisperKey), "The contact row must be selectable")
  send(env, window, "Reply from Wrath")
  assert(#env.sent == 1, "Pressing Enter must reach global SendChatMessage")
  assert(env.sent[1].channel == "WHISPER" and env.sent[1].target == "Jaina", "Whisper target must use local character name")
  assert(env.sent[1].message == "Reply from Wrath")
  chat(env, loadFrame, "CHAT_MSG_WHISPER_INFORM", "Reply from Wrath", "Jaina", 102, "0x0000000000000002")
  assert(#whisper.messages == 2, "Server echo must not duplicate the outgoing message")
  assert(whisper.messages[2].direction == "out")

  runtime.setWindowVisible(false)
  _G.SlashCmdList.WHISPERMESSENGER_REPLY()
  assert(window.frame:IsShown() and runtime.activeConversationKey == whisperKey, "/wr should reopen the last whisper")

  env.ui.Fire(window.optionsButton, "OnClick", "LeftButton")
  assert(window.optionsPanel:IsShown(), "Options button must open settings")
  for _, tab in ipairs({
    window.generalTab,
    window.appearanceTab,
    window.behaviorTab,
    window.notificationsTab,
    window.iconsTab,
    window.whatsNewTab,
  }) do
    env.ui.Fire(tab, "OnClick", "LeftButton")
  end
  env.ui.Fire(window.backButton, "OnClick", "LeftButton")
  assert(not window.optionsPanel:IsShown(), "Back button must return to chat")

  local link = "item:19019:0:0:0:0:0:0:0"
  chat(env, loadFrame, "CHAT_MSG_WHISPER", "|cffff8000|H" .. link .. "|h[Thunderfury]|h|r", "Jaina", 110, "0x0000000000000002")
  local clickable
  for _, object in ipairs(env.ui.objects) do
    if object._wmLegacyLinks and object._wmLegacyLinks:IsShown() then
      clickable = object._wmLegacyLinks
    end
  end
  assert(clickable, "Item links must have a clickable legacy chat widget")
  env.ui.Fire(clickable, "OnHyperlinkEnter", link)
  assert(env.hoveredLink == link, "Hovering an item link must open the tooltip")
  env.ui.Fire(clickable, "OnHyperlinkClick", link, "[Thunderfury]", "LeftButton")
  assert(env.clickedLink == link, "Clicking an item link must call SetItemRef")
  env.ui.Fire(clickable, "OnMouseUp", "RightButton")
  local reactions = ns.ChatBubbleReactionPicker.GetFrame()
  assert(reactions and reactions:IsShown(), "Right-clicking a linked bubble must open reactions and reply")
  ns.ChatBubbleReactionPicker.Close()
  window.conversation.transcript.onReply(whisper.messages[1])
  assert(window.conversation.replyBanner.frame:IsShown(), "Quoting a message must display its reply banner")
  env.ui.Fire(window.composer.input, "OnEscapePressed")
  assert(not window.conversation.replyBanner.frame:IsShown(), "Escape must clear a pending quote")

  env.ui.Fire(window.composer.emojiButton, "OnClick", "LeftButton")
  assert(window.composer.emojiPicker.frame:IsShown(), "Emoji picker must open")
  env.ui.Fire(window.composer.emojiPicker.buttons[1], "OnClick", "LeftButton")
  assert(window.composer.input:GetText():match("^:[%w_]+:$"), "Emoji picker must insert a token")
  window.composer.input:SetText("")
  env.ui.Fire(window.composer.quickReplyButton, "OnClick", "LeftButton")
  assert(window.composer.quickReplyPicker.frame:IsShown(), "Quick-reply picker must open")
  env.ui.Fire(window.composer.quickReplyPicker.rows[1], "OnClick", "LeftButton")
  assert(#window.composer.input:GetText() > 0, "Quick-reply picker must populate the composer")
  window.composer.input:SetText("")

  local contactRow
  for _, row in ipairs(window.contacts.rows) do
    if row.item and row.item.conversationKey == whisperKey then
      contactRow = row
    end
  end
  assert(contactRow, "Whisper row must remain available")
  env.ui.Fire(contactRow, "OnClick", "RightButton")
  assert(env.menu and #env.menu > 2, "Contact menu must open through the Wrath dropdown API")
  local muteAction
  for _, item in ipairs(env.menu) do
    if item.text == "Mute" then
      muteAction = item.func
    end
  end
  assert(muteAction, "Legacy contact menu must retain mute")
  muteAction()
  assert(whisper.muted, "Legacy menu action must persist the preference")
  local nicknameAction
  for _, item in ipairs(env.menu) do
    if item.text:match("^Set nickname") then
      nicknameAction = item.func
    end
  end
  assert(nicknameAction, "Nickname action must be available")
  nicknameAction()
  assert(env.popup and env.popup:IsShown(), "Nickname action must open the shared Blizzard popup")
  _G.StaticPopup1EditBox:SetText("Archmage")
  env.ui.Fire(_G.StaticPopup1Button1, "OnClick", "LeftButton")
  assert(whisper.nickname == "Archmage", "Nickname popup must save its text")

  env.party = 2
  env.ui.Fire(loadFrame, "OnEvent", "PARTY_MEMBERS_CHANGED")
  chat(env, loadFrame, "CHAT_MSG_PARTY", "Party ready", "Jaina", 103, "0x0000000000000002")
  local partyKey, party = findConversation(runtime, "PARTY")
  assert(partyKey and #party.messages == 1, "Wrath party messages must appear in Groups")
  window.setTabMode("groups")
  assert(window.selectConversation(partyKey), "Party conversation must be selectable")
  send(env, window, "Ready")
  assert(#env.sent == 2 and env.sent[2].channel == "PARTY", "Party reply must use global SendChatMessage")
  env.Advance(2)

  chat(env, loadFrame, "CHAT_MSG_GUILD", "Guild hello", "Jaina", 104, "0x0000000000000002")
  local guildKey = findConversation(runtime, "GUILD")
  assert(guildKey and window.selectConversation(guildKey), "Guild chat must appear in Groups")
  send(env, window, "Guild reply")
  assert(#env.sent == 3 and env.sent[3].channel == "GUILD")

  env.raid = 10
  env.ui.Fire(loadFrame, "OnEvent", "RAID_ROSTER_UPDATE")
  chat(env, loadFrame, "CHAT_MSG_RAID", "Raid hello", "Jaina", 105, "0x0000000000000002")
  local raidKey = findConversation(runtime, "RAID")
  assert(raidKey and window.selectConversation(raidKey), "Raid chat must appear in Groups")
  send(env, window, "Raid reply")
  assert(#env.sent == 4 and env.sent[4].channel == "RAID")

  env.instance = "pvp"
  env.ui.Fire(loadFrame, "OnEvent", "PLAYER_ENTERING_WORLD")
  chat(env, loadFrame, "CHAT_MSG_BATTLEGROUND", "Battleground hello", "Jaina", 106, "0x0000000000000002")
  local battlegroundKey = findConversation(runtime, "INSTANCE_CHAT")
  assert(battlegroundKey and window.selectConversation(battlegroundKey), "Legacy battleground chat must appear in Groups")
  send(env, window, "Battleground reply")
  assert(#env.sent == 5 and env.sent[5].channel == "BATTLEGROUND", "Legacy battleground reply must use BATTLEGROUND")

  env.ui.Fire(window.newConversationButton, "OnClick", "LeftButton")
  assert(env.popup and env.popup:IsShown(), "New conversation must open the name prompt")
  _G.StaticPopup1EditBox:SetText("Anduin")
  env.ui.Fire(_G.StaticPopup1Button1, "OnClick", "LeftButton")
  assert(runtime.activeConversationKey:match("anduin"), "New conversation prompt must select the new character")

  local native = ns.MessengerWindow.Create(ns.LegacyWrathUI.WrapFactory(_G), {
    settingsConfig = { nativeChrome = true },
    contacts = {},
  })
  assert(native.frame and native.closeButton and native.title, "Native WoW chrome must build on 3.3.5")
  env.ui.Fire(native.optionsButton, "OnClick", "LeftButton")
  for _, tab in ipairs({
    native.generalTab,
    native.appearanceTab,
    native.behaviorTab,
    native.notificationsTab,
    native.iconsTab,
    native.whatsNewTab,
  }) do
    env.ui.Fire(tab, "OnClick", "LeftButton")
  end

  env.ui.Fire(loadFrame, "OnEvent", "PLAYER_LOGOUT")
  assert(_G.WhisperMessengerDB.conversations[whisperKey], "Whisper history must persist in SavedVariables")
  assert(
    _G.C_Timer == nil and _G.C_ChatInfo == nil and _G.C_FriendList == nil,
    "The port must not replace missing global namespaces used by other addons"
  )
  assert(_G.CreateFrame == legacyFactory, "Other addons must retain the original global CreateFrame")
  _G.require = savedRequire
end
