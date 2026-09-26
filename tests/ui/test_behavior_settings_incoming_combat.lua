local FakeUI = require("tests.helpers.fake_ui")
local FindUI = require("tests.helpers.find_ui")
local BehaviorSettings = require("WhisperMessenger.UI.MessengerWindow.BehaviorSettings")
local Localization = require("WhisperMessenger.Locale.Localization")

local LABEL = "Only auto-open outside combat"
local TOOLTIP =
  "Prevents incoming whispers from opening the messenger during combat. You can still open it manually; message-preview popups are unchanged."
local INCOMING_TOOLTIP = "Opens the messenger when you receive a whisper. The combat popup setting controls whether this can happen during combat."
local LOCALES = { "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }

local function create(config)
  local factory = FakeUI.NewFactory()
  local parent = factory.CreateFrame("Frame", "UIParent", nil)
  local changes = {}
  local result = BehaviorSettings.Create(factory, parent, config or {}, {
    onChange = function(key, value)
      changes[key] = value
    end,
  })
  return result, changes
end

local function tooltipLines(row)
  local previous = _G.GameTooltip
  local lines = {}
  _G.GameTooltip = {
    SetOwner = function() end,
    SetText = function(_, value)
      lines[1] = value
    end,
    AddLine = function(_, value)
      lines[#lines + 1] = value
    end,
    Show = function() end,
    Hide = function() end,
  }
  row:GetScript("OnEnter")(row)
  _G.GameTooltip = previous
  return lines
end

return function()
  Localization.Configure({ language = "enUS" })

  -- New and existing profiles retain the previous combat protection.
  do
    local result, changes = create()
    local toggle = FindUI.toggle(result.frame, LABEL)
    assert(FindUI.isToggleOn(toggle), "incoming combat protection should default on")
    FindUI.click(toggle)
    assert(changes.autoOpenIncomingOutOfCombatOnly == false, "disabling should persist explicit false")
    FindUI.click(toggle)
    assert(changes.autoOpenIncomingOutOfCombatOnly == true, "enabling should persist true")
  end

  -- Saved opt-outs are shown accurately; reset restores the safe default.
  do
    local result, changes = create({ autoOpenIncomingOutOfCombatOnly = false })
    local toggle = FindUI.toggle(result.frame, LABEL)
    assert(not FindUI.isToggleOn(toggle), "saved opt-out should appear off")
    FindUI.click(FindUI.byLabel(result.frame, "Reset to Defaults"))
    assert(changes.autoOpenIncomingOutOfCombatOnly == true, "reset should restore incoming combat protection")
    assert(FindUI.isToggleOn(toggle), "reset should update the toggle display")
  end

  -- The new row belongs to incoming whispers and preserves the scroll extent.
  do
    local result = create({ quickReplies = { "brb" } })
    local incoming = FindUI.byLabel(result.frame, "Auto-open on incoming whisper")
    local combat = FindUI.byLabel(result.frame, LABEL)
    local outgoing = FindUI.byLabel(result.frame, "Auto-open on outgoing whisper")
    assert(combat.point[2] == incoming, "combat setting should follow incoming auto-open")
    assert(outgoing.point[2] == combat, "outgoing toggle should follow the new row")
    local title = FindUI.text(result.frame, "Quick replies (1/10)")
    assert(title.point[2] == FindUI.byLabel(result.frame, "Send read receipts"), "quick replies should remain below all toggles")
    local reset = FindUI.byLabel(result.frame, "Reset to Defaults")
    assert(reset.point[2] == result.quickReplies.bottom, "reset should remain below quick replies")
    assert(result.frame._wmBottomMarker.point[2] == reset, "scroll content should still extend through reset")
    assert(tooltipLines(combat)[2] == TOOLTIP, "combat tooltip should explain manual opening and unchanged previews")
    assert(tooltipLines(incoming)[2] == INCOMING_TOOLTIP, "incoming tooltip should explain configurable combat behavior")
  end

  -- All catalogs translate the new label and both behavior descriptions.
  for _, code in ipairs(LOCALES) do
    local catalog = require("WhisperMessenger.Locale." .. code)
    for _, key in ipairs({ LABEL, TOOLTIP, INCOMING_TOOLTIP }) do
      assert(type(catalog[key]) == "string" and catalog[key] ~= "", code .. " must translate " .. key)
    end
    Localization.Configure({ language = "enUS" })
    local result = create()
    Localization.Configure({ language = code })
    result.setLanguage()
    assert(FindUI.toggle(result.frame, catalog[LABEL]), code .. " should update the combat toggle label live")
    local translated = create()
    assert(tooltipLines(FindUI.byLabel(translated.frame, catalog[LABEL]))[2] == catalog[TOOLTIP], code .. " should translate the tooltip")
  end
  Localization.Configure({ language = "enUS" })
end
