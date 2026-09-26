"""Build an installable archive containing only runtime files."""
from pathlib import Path
import hashlib
import re
import zipfile

root = Path(__file__).resolve().parent.parent
paths = {"WhisperMessenger.toc", "Bindings.xml", "LICENSE", "README-WOTLK.md"}
manifest = (root / "WhisperMessenger.toc").read_text(encoding="utf-8")
version = re.search(r"(?m)^## Version: v?(\d+\.\d+\.\d+)\s*$", manifest)
assert version, "The manifest must contain a release version."
assert re.search(r"(?m)^## Interface: 30300\s*$", manifest), "Only original Wrath packages are supported."
for line in manifest.splitlines():
    line = line.strip()
    if line and not line.startswith("#"):
        paths.add(line.replace("\\", "/"))
paths.update(p.relative_to(root).as_posix() for p in (root / "Media").glob("*.tga"))
paths.update(p.relative_to(root).as_posix() for p in (root / "Media").glob("*.txt"))
destination = root / "dist" / f"WhisperMessenger-{version.group(1)}-WotLK-3.3.5a.zip"
destination.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as archive:
    for name in sorted(paths):
        source = root / name
        assert source.is_file(), f"Missing package file: {source}"
        archive.write(source, f"WhisperMessenger/{name}")
with zipfile.ZipFile(destination) as archive:
    assert archive.testzip() is None
print(destination)
print(f"{len(paths)} files, {destination.stat().st_size:,} bytes")
print(f"SHA256 {hashlib.sha256(destination.read_bytes()).hexdigest()}")
