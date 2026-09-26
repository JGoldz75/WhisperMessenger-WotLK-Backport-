-- Original StaticPopup frames belong to Blizzard and must not need the
-- addon's wrapped factory. Named globals mirror 3.3.5 StaticPopup.xml.
local Popup = {}

function Popup.Install(ui, state)
  _G.StaticPopupDialogs = {}
  _G.StaticPopup_Show = function(which, textArg1, textArg2, data)
    local definition = assert(_G.StaticPopupDialogs[which], which)
    local frame = _G.StaticPopup1
    if not frame then
      frame = ui.CreateFrame("Frame", "StaticPopup1", _G.UIParent)
      frame:SetSize(350, 150)
      frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
      local label = frame:CreateFontString("StaticPopup1Text", "ARTWORK", "GameFontHighlight")
      label:SetText("")
      local input = ui.CreateFrame("EditBox", "StaticPopup1EditBox", frame, "InputBoxTemplate")
      input:SetSize(300, 24)
      input:SetTextInsets(0, 0, 0, 0)
      for _, suffix in ipairs({ "Left", "Middle", "Right" }) do
        input:CreateTexture("StaticPopup1EditBox" .. suffix, "BORDER"):SetTexture("Interface\\Common\\Common-Input-Border")
      end
      for index = 1, 2 do
        local button = ui.CreateFrame("Button", "StaticPopup1Button" .. index, frame, "UIPanelButtonTemplate")
        button:SetSize(100, 22)
        button.fontString = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
      end
    end
    frame.which, frame.data = which, data
    frame:SetScript("OnHide", definition.OnHide)
    _G.StaticPopup1Button1:SetScript("OnClick", function()
      if definition.OnAccept then
        definition.OnAccept(frame, frame.data)
      end
      frame:Hide()
    end)
    _G.StaticPopup1Button2:SetScript("OnClick", function()
      frame:Hide()
    end)
    state.popup = frame
    frame:Show()
    if definition.OnShow then
      definition.OnShow(frame, frame.data)
    end
    return frame
  end
  _G.StaticPopup_Hide = function(which)
    if state.popup and state.popup.which == which then
      state.popup:Hide()
    end
  end
end

return Popup
