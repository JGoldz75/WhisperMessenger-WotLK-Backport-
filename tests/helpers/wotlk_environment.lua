local LegacyUI = require("tests.helpers.wotlk_ui")
local Popup = require("tests.helpers.wotlk_popup")
local Environment = {}

function Environment.Install()
  local ui = LegacyUI.New()
  local state = { now = 1000, sent = {}, addonSent = {}, filters = {}, sounds = {}, errors = {}, party = 0, raid = 0 }
  for key in pairs(_G) do
    if key:match("^C_") then
      _G[key] = nil
    end
  end
  _G.Enum, _G.Settings, _G.BackdropTemplateMixin = nil, nil, nil
  _G.WOW_PROJECT_ID, _G.WOW_PROJECT_MAINLINE = nil, nil
  _G.CreateFrame = ui.CreateFrame
  _G.CreateFont = function(name)
    return ui.CreateFrame("Font", name)
  end
  _G.UIParent = ui.CreateFrame("Frame", "UIParent")
  _G.UIParent:SetSize(1920, 1080)
  _G.Minimap = ui.CreateFrame("Frame", "Minimap", _G.UIParent)
  _G.Minimap:SetSize(140, 140)
  for _, name in ipairs({
    "GameFontNormal",
    "GameFontDisableSmall",
    "GameFontHighlight",
    "GameFontHighlightSmall",
    "GameFontHighlightLarge",
    "ChatFontNormal",
    "GameTooltipText",
    "SystemFont_Small",
    "SystemFont_Med1",
  }) do
    _G.CreateFont(name):SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  end
  _G.GetBuildInfo = function()
    return "3.3.5", "12340", "Jun 24 2010", 30300
  end
  _G.GetLocale = function()
    return "enUS"
  end
  _G.UnitName = function(unit)
    return unit == "player" and "Tester" or "Jaina"
  end
  _G.UnitClass = function()
    return "Mage", "MAGE"
  end
  _G.UnitRace = function()
    return "Human", "Human"
  end
  _G.UnitGUID = function(unit)
    return unit == "player" and "0x0000000000000001" or "0x0000000000000002"
  end
  _G.UnitFactionGroup = function()
    return "Alliance"
  end
  _G.GetRealmName = function()
    return "Frostmourne"
  end
  _G.GetPlayerInfoByGUID = function()
    return "Mage", "MAGE", "Human", "Human", 3, "Jaina", ""
  end
  _G.time = function()
    return state.now
  end
  _G.GetTime = function()
    return state.now
  end
  _G.geterrorhandler = function()
    return function(message)
      state.errors[#state.errors + 1] = tostring(message)
    end
  end
  _G.date = os.date
  _G.GetGameTime = function()
    return 12, 34
  end
  _G.InCombatLockdown = function()
    return false
  end
  _G.GetInstanceInfo = function()
    return "Eastern Kingdoms", "none", 0, "", 0, false
  end
  _G.IsInInstance = function()
    return state.instance ~= nil, state.instance or "none"
  end
  _G.GetNumPartyMembers = function()
    return state.party
  end
  _G.GetNumRaidMembers = function()
    return state.raid
  end
  _G.IsInGuild = function()
    return true
  end
  _G.GetGuildInfo = function()
    return "Test Guild"
  end
  _G.GetNumGuildMembers = function()
    return 1
  end
  _G.GetGuildRosterInfo = function()
    return "Jaina", "Member", 1, 80, "Mage", "Dalaran", "", "", true, 0, "MAGE"
  end
  _G.GuildRoster = function() end
  _G.GetNumFriends = function()
    return 1
  end
  _G.GetFriendInfo = function()
    return "Jaina", 80, "Mage", "Dalaran", true, "", ""
  end
  _G.ShowFriends = function() end
  _G.GetNumIgnores = function()
    return 0
  end
  _G.GetIgnoreName = function() end
  _G.SendChatMessage = function(message, channel, language, target)
    assert(type(message) == "string" and #message <= 255, "3.3.5 chat limit exceeded")
    state.sent[#state.sent + 1] = { message = message, channel = channel, language = language, target = target }
  end
  _G.SendAddonMessage = function(prefix, text, channel, target)
    assert(#prefix + #text <= 254, "3.3.5 addon-message limit exceeded")
    state.addonSent[#state.addonSent + 1] = { prefix = prefix, text = text, channel = channel, target = target }
  end
  _G.ChatFrame_AddMessageEventFilter = function(event, fn)
    state.filters[event] = fn
  end
  _G.ChatFrame_RemoveMessageEventFilter = function(event)
    state.filters[event] = nil
  end
  _G.ChatEdit_SetLastTellTarget = function(target)
    state.lastTell = target
  end
  _G.GetDefaultLanguage = function()
    return "Common", 7
  end
  _G.IsShiftKeyDown = function()
    return false
  end
  _G.IsControlKeyDown = function()
    return false
  end
  _G.IsAltKeyDown = function()
    return false
  end
  _G.GetCursorPosition = function()
    return 100, 100
  end
  _G.MouseIsOver = function()
    return false
  end
  _G.PlaySound = function(name)
    assert(type(name) == "string", "3.3.5 PlaySound takes a sound name")
    state.sounds[#state.sounds + 1] = name
  end
  _G.PlaySoundFile = function(path)
    state.sounds[#state.sounds + 1] = path
  end
  _G.GetBindingKey = function(action)
    if action == "REPLY" then
      return "R"
    end
  end
  _G.SetOverrideBindingClick = function() end
  _G.ClearOverrideBindings = function() end
  _G.hooksecurefunc = function() end
  _G.EasyMenu = function(items, frame)
    state.menu, state.menuFrame = items, frame
  end
  _G.FriendsFrame_ShowDropdown = function(name)
    state.playerMenu = name
  end
  _G.SetItemRef = function(link)
    state.clickedLink = link
  end
  _G.GetCVar = function()
    return "1"
  end
  _G.SlashCmdList, _G.UISpecialFrames = {}, {}
  _G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(_, text)
      state.notice = text
    end,
  }
  _G.GameTooltip = ui.CreateFrame("GameTooltip", "GameTooltip")
  _G.GameTooltip.SetOwner = function(self, owner)
    self.owner = owner
  end
  _G.GameTooltip.GetOwner = function(self)
    return self.owner
  end
  _G.GameTooltip.AddLine = function() end
  _G.GameTooltip.SetHyperlink = function(_, link)
    state.hoveredLink = link
  end
  _G.RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.78, b = 0.92 } }
  _G.ChatTypeInfo = { WHISPER = { r = 1, g = 0.5, b = 1 }, PARTY = { r = 0.7, g = 0.7, b = 1 } }
  Popup.Install(ui, state)
  state.ui = ui
  function state.Advance(seconds)
    state.now = state.now + seconds
    ui.Tick(seconds)
    assert(#state.errors == 0, table.concat(state.errors, "\n"))
  end
  return state
end

return Environment
