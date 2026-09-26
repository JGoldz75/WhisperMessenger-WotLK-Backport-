local Compat = require("WhisperMessenger.Core.FlavorCompat")
local Identity = require("WhisperMessenger.Model.Identity")

return function()
  Compat.isLegacyWrath = true
  _G.Ambiguate = nil
  _G.GetRealmName = function()
    return "Frostmourne"
  end
  local qualified = Identity.FromWhisper("Alice-Frostmourne")
  local bare = Identity.FromWhisper("Alice")
  assert(qualified.contactKey == bare.contactKey, "local realm-qualified and bare whispers share one conversation")
  assert(Identity.FromWhisper("Alice-OtherRealm").contactKey ~= bare.contactKey, "foreign realm-qualified names remain distinct")
  assert(Identity.BuildLocalProfileId("Tester", "Frostmourne") == "tester-frostmourne", "local profile IDs remain realm-scoped")
  local runtime = { store = { conversations = { ["wow::WOW::alice"] = { channel = "WOW", displayName = "Alice" } } } }
  assert(
    Identity.ResolveWhisperConversation(runtime, "Alice-Frostmourne", "WOW") == "wow::WOW::alice",
    "qualified start and reply commands select the existing conversation"
  )
end
