local FakeUI = require("tests.helpers.fake_ui")
local Compat = require("WhisperMessenger.Core.FlavorCompat")
local Shapes = require("WhisperMessenger.UI.Helpers.Shapes")
local ScrollFactory = require("WhisperMessenger.UI.ScrollView.Factory")
local Dropdown = require("WhisperMessenger.UI.MessengerWindow.AppearanceSettings.DropdownSelector")

local function checkClippingPolicy(build, legacy, label)
  Compat.isLegacyWrath = legacy
  local factory = FakeUI.NewFactory()
  local create = factory.CreateFrame
  local calls = 0
  factory.CreateFrame = function(...)
    local frame = create(...)
    frame.SetClipsChildren = function(_, enabled)
      calls = calls + 1
      assert(not legacy, label .. ": must bypass the legacy provider's reparenting clipping shim")
      assert(enabled == true, label .. ": modern clipping must remain enabled")
    end
    return frame
  end
  local parent = factory.CreateFrame("Frame")
  parent:SetSize(400, 300)
  build(factory, parent)
  assert(calls == (legacy and 0 or 1), label .. ": unexpected clipping call count")
end

return function()
  local saved = Compat.isLegacyWrath
  local cases = {
    {
      label = "class portraits",
      build = function(factory, parent)
        Shapes.createCircularIcon(factory, parent, 32)
      end,
    },
    {
      label = "conversation scrolling",
      build = function(factory, parent)
        ScrollFactory.Create(factory, parent, { width = 300, height = 200 })
      end,
    },
    {
      label = "settings dropdowns",
      build = function(factory, parent)
        Dropdown.Create(factory, parent, {
          labelText = "Font Family",
          optionsList = { { key = "default", label = "Default" } },
          initial = "default",
        })
      end,
    },
  }
  for _, case in ipairs(cases) do
    checkClippingPolicy(case.build, true, case.label)
    checkClippingPolicy(case.build, false, case.label)
  end
  Compat.isLegacyWrath = saved
end
