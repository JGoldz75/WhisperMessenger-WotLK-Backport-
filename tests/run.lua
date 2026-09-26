assert(_VERSION == "Lua 5.1", "Run addon tests with the original client's Lua 5.1 runtime")

package.path = table.concat({
  "./?.lua",
  "./?/init.lua",
  package.path,
}, ";")

local rawRequire = require

local function normalizeModuleName(name)
  if type(name) == "string" and string.find(name, "WhisperMessenger.", 1, true) == 1 then
    return string.sub(name, string.len("WhisperMessenger.") + 1)
  end

  return name
end

require = function(name)
  return rawRequire(normalizeModuleName(name))
end
_G.require = require

-- Keep the CLI runner aligned with scripts/run_test.py. Tests needing widgets
-- install fake_ui themselves; the original-Wrath smoke replaces these globals.
_G.C_ChatInfo = _G.C_ChatInfo or {}
_G.GameTooltip = _G.GameTooltip
  or {
    SetOwner = function() end,
    SetText = function() end,
    AddLine = function() end,
    Show = function() end,
    Hide = function() end,
  }

local path = ...
assert(path, "expected a test file path")

local ok, testFn = pcall(dofile, path)
if not ok then
  error(testFn)
end

if type(testFn) == "function" then
  testFn()
end

print("PASS " .. path)
