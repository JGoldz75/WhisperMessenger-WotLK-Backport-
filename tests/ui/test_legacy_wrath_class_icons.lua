local FakeUI = require("tests.helpers.fake_ui")
local Compat = require("WhisperMessenger.Core.FlavorCompat")
local UI = require("WhisperMessenger.Core.LegacyWrath.UI")

return function()
  Compat.isLegacyWrath = true
  local factory = UI.WrapFactory(FakeUI.NewFactory())
  local frame = factory.CreateFrame("Frame")
  local icon = frame:CreateTexture()
  for _, class in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
    -- Recycled textures can retain old atlas coordinates; each new class
    -- must occupy the entire icon, including when changing conversations.
    icon:SetTexCoord(0.75, 1, 0.25, 0.5)
    icon:SetTexture("Interface\\ICONS\\ClassIcon_" .. class)
    local expected = "Interface\\AddOns\\WhisperMessenger\\Media\\class-" .. class .. ".tga"
    assert(icon:GetTexture() == expected, "incorrect standalone icon for " .. class)
    assert(
      icon.texCoords[1] == 0 and icon.texCoords[2] == 1 and icon.texCoords[3] == 0 and icon.texCoords[4] == 1,
      "stale atlas crop must not distort " .. class
    )
    local image = assert(io.open("Media/class-" .. class .. ".tga", "rb"), "missing bundled icon for " .. class)
    local header = image:read(18)
    image:close()
    assert(header:byte(3) == 2 and header:byte(17) == 32, "class icons must be uncompressed RGBA TGA")

    -- Drag ghosts copy GetTexture() directly, so the filename must work
    -- without an extra atlas crop or a dependency on another addon.
    local ghost = frame:CreateTexture()
    ghost:SetTexture(icon:GetTexture())
    assert(ghost:GetTexture() == expected, "drag icon must keep the same standalone artwork")
  end
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  assert(icon.texCoords[1] == 0 and icon.texCoords[2] == 1, "non-class reuse must retain full coordinates")
  Compat.isLegacyWrath = false
end
