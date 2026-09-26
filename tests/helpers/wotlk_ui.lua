-- Deliberately closed 3.3.5 widget surface. Unknown methods stay nil; no
-- catch-all __index, modern templates, or fake C_* namespaces are installed.
local FrameModule = require("tests.helpers.fake_ui.frame")
local Animation = require("tests.helpers.wotlk_animation")
local LegacyUI = {}

local function words(value)
  local result = {}
  for name in value:gmatch("%S+") do
    result[name] = true
  end
  return result
end

local allowed = words([[
  SetSize SetScale GetScale GetEffectiveScale GetSize SetWidth SetHeight
  SetPoint GetPoint ClearAllPoints SetAllPoints SetText GetText
  SetCursorPosition GetCursorPosition SetMultiLine SetAutoFocus
  SetHyperlinksEnabled SetFontObject GetStringHeight Show Hide IsShown IsVisible
  SetScript GetScript HookScript SetAlpha GetAlpha HasFocus SetFocus ClearFocus
  SetScrollChild UpdateScrollChildRect GetVerticalScrollRange SetVerticalScroll
  GetVerticalScroll EnableMouseWheel SetMinMaxValues GetMinMaxValues
  SetValueStep SetOrientation SetThumbTexture SetValue GetValue SetJustifyH
  SetJustifyV SetShadowOffset SetWordWrap SetMaxBytes CreateFontString
  SetTextColor GetTextColor SetTextInsets Insert GetName GetWidth GetHeight
  CreateTexture SetMovable IsMovable StartMoving StopMovingOrSizing StartSizing
  SetFrameStrata GetFrameLevel SetFrameLevel Raise Lower GetParent SetParent
  EnableMouse RegisterForDrag SetResizable SetMinResize GetRegions GetChildren
  GetStringWidth GetTextWidth SetClampedToScreen SetNormalFontObject
  SetHighlightFontObject SetNormalTexture GetNormalTexture SetPushedTexture
  SetHighlightTexture SetDisabledTexture SetBackdrop GetBackdrop SetBackdropColor
  SetBackdropBorderColor RegisterEvent UnregisterEvent IsEventRegistered
  SetTexture GetTexture SetVertexColor SetDesaturated SetTexCoord SetBlendMode
]])

local templates = words([[
  SecureActionButtonTemplate UIPanelButtonTemplate UIPanelCloseButton UIDropDownMenuTemplate
  UICheckButtonTemplate OptionsCheckButtonTemplate OptionsSliderTemplate
  InputBoxTemplate InputBoxInstructionsTemplate GameFontNormal GameFontHighlight
  GameFontHighlightSmall GameFontDisableSmall ChatFontNormal GameTooltipText
  GameFontHighlightLarge SystemFont_Small SystemFont_Med1
]])

function LegacyUI.New()
  local base = FrameModule.makeCreateFrame()
  local all = {}
  local unsupportedEvents = words([[
    CAN_LOCAL_WHISPER_TARGET_RESPONSE CHAT_MSG_INSTANCE_CHAT CHAT_MSG_INSTANCE_CHAT_LEADER
    CHAT_MSG_COMMUNITIES_CHANNEL CLUB_MEMBER_UPDATED CLUB_MEMBER_ADDED CLUB_MEMBER_REMOVED
    GROUP_ROSTER_UPDATE GROUP_FORMED GROUP_JOINED GROUP_LEFT CHALLENGE_MODE_START
    CHALLENGE_MODE_COMPLETED CHALLENGE_MODE_RESET ENCOUNTER_START ENCOUNTER_END
    ADDON_RESTRICTION_STATE_CHANGED BN_CHAT_MSG_ADDON
  ]])
  local create
  create = function(kind, name, parent, template)
    assert(kind ~= "MaskTexture", "MaskTexture did not exist in 3.3.5")
    if template then
      for token in template:gmatch("[^, ]+") do
        assert(templates[token] or token:match("^WM_"), "Unsupported 3.3.5 template: " .. token)
      end
    end
    -- Handle templates ourselves to avoid importing modern child methods.
    local obj = base(kind, name, parent)
    obj.template = template
    for key, value in pairs(obj) do
      if type(value) == "function" and not allowed[key] then
        obj[key] = nil
      end
    end
    obj.shown = true -- WoW-created regions and frames are shown by default.
    obj.HasScript = function(_, event)
      return not event:match("^OnHyperlink") or kind == "ScrollingMessageFrame" or kind == "SimpleHTML" or kind == "GameTooltip"
    end
    obj.SetScript = function(self, event, fn)
      assert(self:HasScript(event), "3.3.5 " .. kind .. " does not support " .. event)
      self.scripts = self.scripts or {}
      self.scripts[event] = fn
    end
    obj.CreateAnimationGroup = Animation.Create
    if kind ~= "ScrollingMessageFrame" and kind ~= "SimpleHTML" and kind ~= "GameTooltip" then
      obj.SetHyperlinksEnabled = nil
    end
    if kind == "ScrollingMessageFrame" then
      obj.Clear = function(self)
        self.messages = {}
      end
      obj.AddMessage = function(self, text)
        self.messages = self.messages or {}
        self.messages[#self.messages + 1] = text
      end
      obj.SetFading = function(self, fading)
        self.fading = fading
      end
      obj.SetMaxLines = function(self, count)
        self.maxLines = count
      end
    end
    obj.RegisterEvent = function(self, event)
      assert(not unsupportedEvents[event], "Attempt to register unknown event: " .. event)
      self.events = self.events or {}
      self.events[event] = true
    end
    all[#all + 1] = obj
    if name then
      _G[name] = obj
    end
    obj.CreateTexture = function(self, childName, layer, inherited)
      local tex = create("Texture", childName, self, inherited)
      tex.layer = layer
      return tex
    end
    obj.CreateFontString = function(self, childName, layer, inherited)
      local font = create("FontString", childName, self, inherited)
      font.layer = layer
      if inherited then
        font:SetFontObject(inherited)
      end
      return font
    end
    obj.SetFont = function(self, path, size, flags)
      assert(type(path) == "string", "3.3.5 SetFont expects a path")
      self.fontPath, self.fontSize, self.fontFlags = path, size, flags
      return true
    end
    obj.GetFont = function(self)
      return self.fontPath or "Fonts\\FRIZQT__.TTF", self.fontSize or 12, self.fontFlags or ""
    end
    obj.SetFontObject = function(self, font)
      if type(font) == "string" then
        font = assert(_G[font], "Unknown font " .. font)
      end
      self.fontObject = font
      if font and font.GetFont then
        self:SetFont(font:GetFont())
      end
    end
    obj.SetShadowColor = function(self, ...)
      self.shadowColor = { ... }
    end
    obj.SetNonSpaceWrap = function(self, value)
      self.nonSpaceWrap = value
    end
    obj.SetMaxResize = function(self, ...)
      self.maxResize = { ... }
    end
    obj.GetObjectType = function(self)
      return self.frameType
    end
    obj.GetLeft = function()
      return 100
    end
    obj.GetTop = function(self)
      return 100 + self:GetHeight()
    end
    obj.GetBottom = function()
      return 100
    end
    obj.GetRight = function(self)
      return 100 + self:GetWidth()
    end
    obj.GetCenter = function(self)
      return 100 + self:GetWidth() / 2, 100 + self:GetHeight() / 2
    end
    obj.RegisterForClicks = function(self, ...)
      self.clicks = { ... }
    end
    obj.SetAttribute = function(self, key, value)
      self.attributes = self.attributes or {}
      self.attributes[key] = value
    end
    obj.GetAttribute = function(self, key)
      return self.attributes and self.attributes[key]
    end
    obj.Enable = function(self)
      self.enabled = true
    end
    obj.Disable = function(self)
      self.enabled = false
    end
    obj.IsEnabled = function(self)
      return self.enabled ~= false
    end
    obj.HighlightText = function(self, ...)
      self.highlight = { ... }
    end
    obj.SetMaxLetters = function(self, count)
      self.maxLetters = count
    end
    obj.SetAltArrowKeyMode = function(self, value)
      self.altArrowKeyMode = value
    end
    obj.GetTextInsets = function(self)
      return unpack(self.textInsets or { 0, 0, 0, 0 })
    end
    obj.GetFontString = function(self)
      return self.fontString
    end
    if kind == "Texture" then
      obj.SetTexture = function(self, ...)
        local first = ...
        assert(type(first) ~= "number" or select("#", ...) >= 3, "3.3.5 SetTexture requires a file path or RGB, not a numeric file ID")
        self.texture = { ... }
      end
      obj.GetTexture = function(self)
        return self.texture and self.texture[1]
      end
      obj.SetTexCoord = function(self, ...)
        self.texCoords = { ... }
      end
      obj.SetVertexColor = function(self, ...)
        self.vertexColor = { ... }
      end
      obj.SetBlendMode = function(self, mode)
        self.blendMode = mode
      end
      obj.SetDesaturated = function(self, value)
        self.desaturated = value
      end
    end
    -- Texture-valued button APIs expose actual regions in the client.
    for _, which in ipairs({ "Normal", "Pushed", "Highlight", "Disabled", "Thumb" }) do
      obj["Set" .. which .. "Texture"] = function(self, texture)
        if type(texture) == "string" then
          local region = create("Texture", nil, self)
          region:SetTexture(texture)
          texture = region
        end
        self[which .. "Texture"] = texture
      end
      obj["Get" .. which .. "Texture"] = function(self)
        return self[which .. "Texture"]
      end
    end
    return obj
  end
  local api = { CreateFrame = create, objects = all }
  function api.Fire(obj, script, ...)
    local handler = obj:GetScript(script)
    if handler then
      handler(obj, ...)
    end
    if obj._hookScripts and obj._hookScripts[script] then
      for _, fn in ipairs(obj._hookScripts[script]) do
        fn(obj, ...)
      end
    end
  end
  function api.Tick(elapsed)
    -- Snapshot: OnUpdate may create more frames or queue future timers.
    local count = #all
    for i = 1, count do
      local obj = all[i]
      if obj:IsVisible() then
        api.Fire(obj, "OnUpdate", elapsed)
      end
    end
  end
  return api
end

return LegacyUI
