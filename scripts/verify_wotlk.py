"""Run the complete Lua suite with Lua 5.1 and validate every shipped chunk."""
import concurrent.futures
import json
import os
from pathlib import Path
import subprocess
import sys

from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parent.parent
os.chdir(root)
lua = LuaRuntime(unpack_returned_tuples=True)
compile_lua = lua.eval("function(path) local f,e=loadfile(path); return f~=nil,e end")
manifest = [line.strip() for line in Path("WhisperMessenger.toc").read_text().splitlines()]
shipped = [name for name in manifest if name and not name.startswith("#")]
for name in shipped:
    assert "/" not in name, f"Original Wrath TOC requires backslashes: {name}"
    name = name.replace("\\", "/")
    assert Path(name).is_file(), f"Missing shipped file: {name}"
    if name.endswith(".lua"):
        ok, error = compile_lua(name)
        assert ok, error
print(f"Lua 5.1 compile/load-list: {len(shipped)} files OK", flush=True)

def run(path):
    process = subprocess.run(
        [sys.executable, "scripts/run_test.py", str(path)],
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    return {"file": path.as_posix(), "passed": process.returncode == 0,
            "output": process.stdout + process.stderr if process.returncode else ""}

with concurrent.futures.ThreadPoolExecutor(max_workers=6) as executor:
    results = list(executor.map(run, sorted(Path("tests").rglob("test*.lua"))))
failures = [result for result in results if not result["passed"]]
Path("verification-results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
print(f"Lua 5.1 tests: {len(results)-len(failures)}/{len(results)} passed")
for failure in failures:
    print(failure["output"])
sys.exit(bool(failures))
