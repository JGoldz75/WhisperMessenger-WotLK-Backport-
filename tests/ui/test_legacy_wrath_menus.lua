local FakeUI = require("tests.helpers.fake_ui")
local Compat = require("WhisperMessenger.Core.FlavorCompat")
local ContextMenu = require("WhisperMessenger.UI.ContactsList.ContextMenu")

return function()
  local saved = Compat.isLegacyWrath
  Compat.isLegacyWrath = true
  local factory = FakeUI.NewFactory()
  _G.UIParent = factory.CreateFrame("Frame")
  local menu
  _G.EasyMenu = function(items)
    menu = items
  end
  local updates
  local contact = { channel = "WOW", displayName = "Arthas", unansweredCount = 2 }
  local opened = ContextMenu.Open(contact, _G.UIParent, function() end, function(item, changes)
    updates = { item, changes }
  end)
  assert(opened and menu, "legacy contact preferences must open an original-client dropdown")
  local function find(text)
    for _, item in ipairs(menu) do
      if item.text == text then
        return item
      end
    end
  end
  assert(find("Mark last messages as unread"), "legacy menu must retain unread action")
  assert(find("Set nickname…") and find("Edit note…"), "legacy menu must retain nickname and note actions")
  assert(find("Mute"), "legacy menu must retain mute")
  find("Mute").func()
  assert(updates[1] == contact and updates[2].muted == true, "legacy mute must update selected contact")
  menu = nil
  assert(ContextMenu.Open({ channel = "PARTY" }, _G.UIParent, nil, function() end), "legacy groups must have a preferences menu")
  assert(find("Mute") and not find("Edit note…"), "legacy group menu must contain only group actions")
  Compat.isLegacyWrath = saved
  _G.EasyMenu = nil
end
