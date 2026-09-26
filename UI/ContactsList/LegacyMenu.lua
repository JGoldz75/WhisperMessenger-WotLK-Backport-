local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local LegacyUI = ns.LegacyWrathUI or require("WhisperMessenger.Core.LegacyWrath.UI")
local LegacyMenu = {}
local menuFrame

-- Present the same addon actions through Wrath's dropdown API. This small
-- description adapter keeps the menu action definitions shared with Retail.
function LegacyMenu.Open(anchor, build)
  if type(_G.EasyMenu) ~= "function" or type(_G.CreateFrame) ~= "function" then
    return false
  end
  if not menuFrame then
    menuFrame = LegacyUI.CreateFrame("Frame", "WhisperMessengerContactMenu", _G.UIParent, "UIDropDownMenuTemplate")
  end
  local items = {}
  local root = {}
  function root:CreateButton(text, callback)
    local item = { text = text, func = callback, notCheckable = true }
    function item.SetEnabled(button, enabled)
      button.disabled = not enabled
    end
    items[#items + 1] = item
    return item
  end
  function root:CreateCheckbox(text, checked, callback)
    items[#items + 1] = { text = text, checked = checked(), func = callback, isNotRadio = true }
  end
  function root:CreateTitle(text)
    items[#items + 1] = { text = text, isTitle = true, notCheckable = true }
  end
  build(root)
  if #items == 0 then
    return false
  end
  _G.EasyMenu(items, menuFrame, anchor or "cursor", 0, 0, "MENU")
  return true
end

ns.ContactsListLegacyMenu = LegacyMenu
return LegacyMenu
