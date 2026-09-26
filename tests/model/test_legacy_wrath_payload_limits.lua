local Compat = require("WhisperMessenger.Core.FlavorCompat")

return function()
  Compat.isLegacyWrath = true
  local QuestLinkExchange = require("WhisperMessenger.Model.QuestLinkExchange")
  local Protocol = require("WhisperMessenger.Model.MessageReactionProtocol")
  local quest = QuestLinkExchange.Encode("[" .. string.rep("x", 249) .. " (1)] [Small (2)]")
  assert(quest == "2:Small", "legacy quest packets account for WMQL prefix and separator")
  local accepted = QuestLinkExchange.Encode("[" .. string.rep("x", 248) .. " (1)]")
  assert(#accepted == 250, "legacy quest packets accept the full 250-byte payload")
  assert(Protocol.MAX_PAYLOAD_BYTES == 250, "legacy reaction protocol reserves prefix and separator")
  local base = Protocol.EncodeGroupReaction("set", "heart", "abc", "source", "fallback", "", "a")
  local oversized = Protocol.EncodeGroupReaction("set", "heart", "abc", "source", "fallback", "", string.rep("a", 252 - #base))
  assert(oversized == nil, "reaction encoder rejects packets above the legacy cap")
end
