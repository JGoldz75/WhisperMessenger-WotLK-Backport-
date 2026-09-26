return function()
  _G.GetBuildInfo = function()
    return "3.3.5", "12340", "", 30300
  end
  local Detector = require("WhisperMessenger.Core.ContentDetector")
  assert(not Detector.IsCompetitiveContent(function()
    return "Warsong Gulch", "pvp"
  end), "original Wrath battlegrounds do not have Retail's addon whisper restrictions")
  assert(not Detector.IsCompetitiveContent(function()
    return "Arena", "arena"
  end))
  assert(not Detector.IsMythicRestricted(function()
    return "Instance", "party", 8
  end))
end
