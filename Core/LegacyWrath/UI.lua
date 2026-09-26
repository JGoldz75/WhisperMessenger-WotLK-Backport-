local addonName, ns = ...
if type(ns) ~= "table" then
  ns = {}
end

-- Adapt only this addon's widgets; never replace Blizzard's global factory
-- or the shared widget metatables used by other addons.
local FlavorCompat = ns.FlavorCompat or require("WhisperMessenger.Core.FlavorCompat")
local UI = {}
local adapted = setmetatable({}, { __mode = "k" })

local function setShown(self, shown)
  if shown then
    self:Show()
  else
    self:Hide()
  end
end

local function setSize(self, width, height)
  self:SetWidth(width)
  self:SetHeight(height)
end

local function setColorTexture(self, r, g, b, a)
  self:SetTexture(r, g, b, a or 1)
end

local function isMouseOver(self)
  return type(_G.MouseIsOver) == "function" and not not _G.MouseIsOver(self) or false
end

local function setEnabled(self, enabled)
  if enabled then
    self:Enable()
  else
    self:Disable()
  end
end

-- Custom clients can replace the shared class atlas with a different grid.
-- Individual bundled artwork is stable across those client replacements.
local CLASS_TAGS = {
  WARRIOR = true,
  MAGE = true,
  ROGUE = true,
  DRUID = true,
  HUNTER = true,
  SHAMAN = true,
  PRIEST = true,
  WARLOCK = true,
  PALADIN = true,
  DEATHKNIGHT = true,
}

local function adaptTexture(region)
  if not FlavorCompat.isLegacyWrath or not region.SetTexture then
    return
  end
  local setTexture = region.SetTexture
  local hadClassIcon = false
  region.SetTexture = function(self, path, ...)
    if type(path) == "string" then
      if path:find("TempPortraitAlphaMask", 1, true) then
        path = "Interface\\AddOns\\WhisperMessenger\\Media\\circle.tga"
      end
      local class = path:match("ClassIcon_(%u+)$") or path:match("\\Media\\class%-(%u+)%.tga$")
      if class and CLASS_TAGS[class] then
        setTexture(self, "Interface\\AddOns\\WhisperMessenger\\Media\\class-" .. class .. ".tga")
        self:SetTexCoord(0, 1, 0, 1)
        hadClassIcon = true
        return
      end
      if path == "Interface\\CHATFRAME\\UI-ChatIcon-ArmoryChat" or path == "Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon" then
        path = "Interface\\Icons\\INV_Misc_Note_01"
      end
    end
    if hadClassIcon and self.SetTexCoord then
      self:SetTexCoord(0, 1, 0, 1)
      hadClassIcon = false
    end
    return setTexture(self, path, ...)
  end
end

function UI.AdaptRegion(region)
  if not region or adapted[region] then
    return region
  end
  adapted[region] = true
  adaptTexture(region)
  if not region.SetShown and region.Show and region.Hide then
    region.SetShown = setShown
  end
  if not region.SetSize and region.SetWidth and region.SetHeight then
    region.SetSize = setSize
  end
  if not region.SetColorTexture and region.SetTexture then
    region.SetColorTexture = setColorTexture
  end
  if not region.IsMouseOver and (region.GetLeft or region.SetScript) then
    region.IsMouseOver = isMouseOver
  end
  if not region.SetEnabled and region.Enable and region.Disable then
    region.SetEnabled = setEnabled
  end
  for _, method in ipairs({ "CreateTexture", "CreateFontString" }) do
    local create = region[method]
    if create then
      region[method] = function(self, ...)
        return UI.AdaptRegion(create(self, ...))
      end
    end
  end
  return region
end

local function createFrame(create, frameType, name, parent, template)
  local nativeWindow = template == "BasicFrameTemplateWithInset"
  if nativeWindow or template == "BackdropTemplate" then
    template = nil
  end
  local frame = UI.AdaptRegion(create(frameType, name, parent, template))
  if nativeWindow then
    if frame.SetBackdrop then
      frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
      })
    end
    frame.Bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.Bg:SetAllPoints(frame)
    frame.Bg:SetColorTexture(0.04, 0.04, 0.04, 0.85)
    frame.TitleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.TitleText:SetPoint("TOP", frame, "TOP", 0, -12)
    frame.CloseButton = UI.AdaptRegion(create("Button", nil, frame, "UIPanelCloseButton"))
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
  end
  return frame
end

function UI.WrapFactory(factory)
  if factory._wmLegacyUIFactory then
    return factory
  end
  local wrapped = { _wmLegacyUIFactory = true }
  setmetatable(wrapped, { __index = factory })
  wrapped.CreateFrame = function(...)
    return createFrame(factory.CreateFrame, ...)
  end
  return wrapped
end

function UI.CreateFrame(...)
  return UI.AdaptRegion(_G.CreateFrame(...))
end

ns.LegacyWrathUI = UI
return UI
