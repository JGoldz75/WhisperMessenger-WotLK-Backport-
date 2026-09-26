local FakeUI = require("tests.helpers.fake_ui")
local Compat = require("WhisperMessenger.Core.FlavorCompat")
local UI = require("WhisperMessenger.Core.LegacyWrath.UI")

return function()
  Compat.isLegacyWrath = true
  local factory = UI.WrapFactory(FakeUI.NewFactory())
  local texture = factory.CreateFrame("Frame"):CreateTexture()
  texture:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
  assert(
    texture.texturePath == "Interface\\AddOns\\WhisperMessenger\\Media\\circle.tga",
    "rounded UI must use a bundled original-client-compatible circle"
  )
  texture:SetTexture("Interface\\ICONS\\ClassIcon_MAGE")
  assert(
    texture.texturePath == "Interface\\AddOns\\WhisperMessenger\\Media\\class-MAGE.tga",
    "class portraits must use individual bundled icons because Frostmourne replaces the class atlas"
  )
  assert(texture.texCoords[1] == 0 and texture.texCoords[2] == 1, "individual class art must use its full width")
  assert(texture.texCoords[3] == 0 and texture.texCoords[4] == 1, "individual class art must use its full height")
  texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  assert(texture.texCoords[1] == 0 and texture.texCoords[2] == 1, "pooled class icons must reset their crop for non-class images")
  local Shapes = require("WhisperMessenger.UI.Helpers.Shapes")
  local icon = Shapes.createCircularIcon(factory, nil, 32)
  assert(icon.texture:GetWidth() == 32, "original-client portraits must fit without unsupported clipping")
  local rawFrame = FakeUI.NewFactory().CreateFrame("Frame")
  local rounded = Shapes.createRoundedBackground(rawFrame, 8)
  assert(
    rounded.corners[1].texturePath == "Interface\\AddOns\\WhisperMessenger\\Media\\circle.tga",
    "popup corners created by Blizzard-owned frames need bundled circle art"
  )
  Compat.isLegacyWrath = false
end
