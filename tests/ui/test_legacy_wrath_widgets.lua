local FakeUI = require("tests.helpers.fake_ui")

return function()
  local ok, UI = pcall(require, "WhisperMessenger.Core.LegacyWrath.UI")
  assert(ok and type(UI.WrapFactory) == "function", "legacy UI factory adapter must exist")
  local native = FakeUI.NewFactory()
  local untouched = native.CreateFrame("Frame")
  local function legacyRegion(region)
    region.SetSize = nil
    region.SetShown = nil
    region.SetColorTexture = nil
    local oldSetTexture = region.SetTexture
    region.SetTexture = function(self, ...)
      if type((...)) == "number" then
        self.legacyColor = { ... }
      elseif oldSetTexture then
        oldSetTexture(self, ...)
      end
    end
    return region
  end
  local rawCreate = native.CreateFrame
  native.CreateFrame = function(...)
    local template = select(4, ...)
    assert(template ~= "BackdropTemplate" and template ~= "BasicFrameTemplateWithInset", "modern templates cannot load")
    local frame = legacyRegion(rawCreate(...))
    frame.IsMouseOver = nil
    frame.SetEnabled = nil
    frame.Enable = function(self)
      self.enabled = true
    end
    frame.Disable = function(self)
      self.enabled = false
    end
    local texture = frame.CreateTexture
    frame.CreateTexture = function(self, ...)
      return legacyRegion(texture(self, ...))
    end
    local font = frame.CreateFontString
    frame.CreateFontString = function(self, ...)
      return legacyRegion(font(self, ...))
    end
    return frame
  end
  local factory = UI.WrapFactory(native)
  assert(factory ~= native, "adapter must not modify the supplied factory")
  local frame = factory.CreateFrame("Frame")
  frame:SetSize(42, 17)
  assert(frame:GetWidth() == 42 and frame:GetHeight() == 17, "legacy width and height must be applied")
  frame:SetShown(true)
  assert(frame:IsShown(), "legacy frame must show")
  frame:SetShown(false)
  assert(not frame:IsShown(), "legacy frame must hide")
  local texture = frame:CreateTexture()
  texture:SetColorTexture(0.1, 0.2, 0.3, 0.4)
  assert(texture.legacyColor[4] == 0.4, "solid colors must use original SetTexture RGBA")
  local font = frame:CreateFontString()
  font:SetShown(true)
  assert(font:IsShown(), "font strings must be adapted too")
  _G.MouseIsOver = function(target)
    return target == frame and 1 or nil
  end
  assert(frame:IsMouseOver() == true, "mouse hover must use MouseIsOver on original Wrath")
  frame:SetEnabled(false)
  assert(frame.enabled == false, "button enable state must map to Disable")
  local window = factory.CreateFrame("Frame", "LegacyWindow", nil, "BackdropTemplate")
  assert(window, "custom window must not request modern backdrop template")
  local classic = factory.CreateFrame("Frame", "LegacyNativeWindow", nil, "BasicFrameTemplateWithInset")
  assert(classic.TitleText and classic.CloseButton and classic.Bg, "native window must supply original-client chrome")
  assert(UI.WrapFactory(factory) == factory, "wrapping a factory twice must be idempotent")
  assert(untouched.SetColorTexture == nil, "unrelated frames must not be modified")
  _G.MouseIsOver = nil
end
