-- The original client does not normalize modern forward-slash TOC paths.
-- Windows Lua loadfile() does, so ordinary TOC smoke tests miss this failure.
return function()
  local count = 0
  local interface
  for line in io.lines("WhisperMessenger.toc") do
    local path = line:match("^%s*(.-)%s*$")
    interface = path:match("^## Interface:%s*(%d+)$") or interface
    if path ~= "" and path:sub(1, 1) ~= "#" then
      assert(not path:find("/", 1, true), "Original Wrath TOC requires backslashes: " .. path)
      local file = assert(io.open(path:gsub("\\", "/"), "rb"))
      file:close()
      count = count + 1
    end
  end
  assert(count > 300, "The complete original addon must remain in the manifest")
  assert(interface == "30300", "Releases must keep the original Wrath interface version 30300")
end
