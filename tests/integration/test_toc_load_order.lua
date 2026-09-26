-- The live client exposes a global `require` that throws for unknown modules,
-- so every file's `ns.X or require(...)` fallback must never be reached:
-- each dependency has to load earlier in the TOC.
local FakeUI = require("tests.helpers.fake_ui")

return function()
  local savedRequire = require
  local savedLoadfile = loadfile
  local savedCreateFrame = _G.CreateFrame
  local factory = FakeUI.NewFactory()

  rawset(_G, "CreateFrame", factory.CreateFrame)
  _G.require = function(moduleName)
    error("Invalid import: No module with that name exists (" .. tostring(moduleName) .. ")")
  end
  -- Linux loadfile does not normalize Windows separators like Windows does.
  -- Exercise that contract here even when the test itself runs on Windows.
  _G.loadfile = function(path)
    assert(not path:find("\\", 1, true), "TOC test loader must normalize paths: " .. path)
    return savedLoadfile(path)
  end

  local ns = {}
  local ok, err = pcall(function()
    for line in io.lines("WhisperMessenger.toc") do
      line = line:match("^%s*(.-)%s*$")
      if line ~= "" and string.sub(line, 1, 2) ~= "##" and not string.match(line, "%.xml$") then
        local chunk = assert(loadfile((line:gsub("\\", "/"))))
        local loaded, loadErr = pcall(chunk, "WhisperMessenger", ns)
        assert(loaded, line .. ": " .. tostring(loadErr))
      end
    end
  end)

  _G.require = savedRequire
  _G.loadfile = savedLoadfile
  rawset(_G, "CreateFrame", savedCreateFrame)

  assert(ok, tostring(err))
end
