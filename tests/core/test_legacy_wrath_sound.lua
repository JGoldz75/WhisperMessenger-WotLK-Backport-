return function()
  _G.GetBuildInfo = function()
    return "3.3.5", "12340", "", 30300
  end
  local sound, channel
  _G.PlaySound = function(value, output)
    assert(type(value) == "string", "3.3.5 PlaySound requires a sound name")
    sound, channel = value, output
  end
  local SoundPlayer = require("WhisperMessenger.Core.SoundPlayer")
  SoundPlayer.Play({ notificationSound = "whisper" })
  assert(sound == "TellMessage" and channel == nil)
  SoundPlayer.Preview("raid_warning")
  assert(sound == "RaidWarning")
  SoundPlayer.Preview("sigil")
  assert(sound == "TellMessage", "newer sound choices fall back to an existing Wrath sound")
end
