local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

local Hyperlinks = ns.UIHyperlinks or require("WhisperMessenger.UI.Hyperlinks")
local LegacyLinks = {}

local function forward(frame, event, ...)
  local handler = frame.GetScript and frame:GetScript(event)
  if handler then
    handler(frame, ...)
  end
end

-- In 3.3.5 only chat widgets understand clickable |H links. Keep the
-- fontstring for measurement and use one persistent child for linked text.
function LegacyLinks.Update(factory, frame, label, text, width, height)
  if not frame.HasScript or frame:HasScript("OnHyperlinkClick") then
    return
  end
  local links = frame._wmLegacyLinks
  if not string.find(text, "|H", 1, true) then
    if links then
      links:Hide()
    end
    label:SetAlpha(1)
    return
  end
  if not links then
    links = factory.CreateFrame("ScrollingMessageFrame", nil, frame)
    links:SetFading(false)
    links:SetMaxLines(1)
    links:SetJustifyH("LEFT")
    links:SetJustifyV("TOP")
    links:EnableMouse(true)
    if links.SetHyperlinksEnabled then
      links:SetHyperlinksEnabled(true)
    end
    links:SetScript("OnHyperlinkClick", function(self, link, display, button)
      Hyperlinks.HandleClick(link, display, button, self)
    end)
    links:SetScript("OnHyperlinkEnter", function(self, link)
      Hyperlinks.HandleEnter(self, link)
    end)
    links:SetScript("OnHyperlinkLeave", Hyperlinks.HandleLeave)
    for _, event in ipairs({ "OnMouseDown", "OnMouseUp", "OnEnter", "OnLeave" }) do
      links:SetScript(event, function(_, ...)
        forward(frame, event, ...)
      end)
    end
    frame._wmLegacyLinks = links
  end
  if label.GetFont and links.SetFont then
    links:SetFont(label:GetFont())
  elseif links.SetFontObject then
    links:SetFontObject(label.fontObject or "ChatFontNormal")
  end
  links:ClearAllPoints()
  links:SetPoint("TOPLEFT", label, "TOPLEFT", 0, 0)
  links:SetSize(width, height + 2)
  links:Clear()
  local r, g, b = label:GetTextColor()
  links:AddMessage(text, r, g, b)
  label:SetAlpha(0)
  links:Show()
end

ns.ChatBubbleLegacyLinks = LegacyLinks
return LegacyLinks
