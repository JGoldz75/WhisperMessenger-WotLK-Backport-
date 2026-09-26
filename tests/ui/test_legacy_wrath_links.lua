local FakeUI = require("tests.helpers.fake_ui")
local BubbleStructure = require("WhisperMessenger.UI.ChatBubble.BubbleStructure")

return function()
  local factory = FakeUI.NewFactory()
  local frame = factory.CreateFrame("Button")
  local rawSetScript = frame.SetScript
  frame.HasScript = function(_, event)
    return not event:match("^OnHyperlink")
  end
  frame.SetScript = function(self, event, handler)
    assert(self:HasScript(event), "original Wrath buttons have no hyperlink scripts")
    rawSetScript(self, event, handler)
  end
  local _, _, label = BubbleStructure.createStructure(frame)
  assert(label ~= nil, "legacy bubbles must build without unsupported script registration")
  local Links = require("WhisperMessenger.UI.ChatBubble.LegacyLinks")
  local rawCreate = factory.CreateFrame
  factory.CreateFrame = function(kind, ...)
    local result = rawCreate(kind, ...)
    result.SetFading = function() end
    result.SetMaxLines = function() end
    result.Clear = function(self)
      self.message = nil
    end
    result.AddMessage = function(self, text, r, g, b)
      self.message = text
      self.messageColor = { r, g, b }
    end
    return result
  end
  label:SetTextColor(0.2, 0.4, 0.6)
  local text = "Try |Hitem:123:0:0:0|h[An item]|h"
  Links.Update(factory, frame, label, text, 180, 32)
  local links = assert(frame._wmLegacyLinks, "legacy links must use a message frame")
  assert(links.frameType == "ScrollingMessageFrame", "native legacy chat widget required for clickable links")
  assert(links.hyperlinksEnabled == true, "legacy chat hyperlinks must be enabled")
  assert(links.message == text, "hyperlink text must retain its original payload")
  assert(links.messageColor[1] == 0.2, "link renderer must retain the chosen message text color")
  assert(label:GetAlpha() == 0, "measuring fontstring must not duplicate visible text")
  local clicked
  _G.SetItemRef = function(link)
    clicked = link
  end
  links.scripts.OnHyperlinkClick(links, "item:123:0:0:0", "[An item]", "LeftButton")
  assert(clicked == "item:123:0:0:0", "legacy links must open normal item tooltips")
  Links.Update(factory, frame, label, "plain text", 180, 16)
  assert(not links:IsShown() and label:GetAlpha() == 1, "pooled plain messages must hide previous link renderers")
  _G.SetItemRef = nil
end
