#!/usr/bin/env bash
# Prepare an original-Wrath release locally; publishing is a separate tag push.
# Usage: bash scripts/release.sh <version> (accepts X.Y.Z or vX.Y.Z)
# Promotes [Unreleased], regenerates What's New, bumps versions, commits and tags.
# The original 3.3.5 client interface is permanently 30300. No CDN is consulted.
set -euo pipefail
cd "$(dirname "$0")/.."

INPUT_VERSION="${1:-}"
if ! [[ "$INPUT_VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage: bash scripts/release.sh <version> (e.g. 2.0.3 or v2.0.3)"
  exit 1
fi
NORMALIZED_VERSION="${INPUT_VERSION#v}"
TAG_VERSION="v${NORMALIZED_VERSION}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: Working tree is not clean. Commit or stash changes first."
  exit 1
fi
if git show-ref --verify --quiet "refs/tags/${TAG_VERSION}"; then
  echo "Error: Tag '${TAG_VERSION}' already exists."
  exit 1
fi

# Check the fixed client target before changing any release files.
python - <<'PY'
from pathlib import Path
import re

toc = Path("WhisperMessenger.toc").read_text(encoding="utf-8")
if not re.search(r"(?m)^## Interface: 30300$", toc):
    raise SystemExit("Error: WhisperMessenger.toc must target original Wrath (Interface: 30300).")
PY

# A missing/ambiguous notes section fails before the version files are edited.
python scripts/promote_changelog.py --version "${TAG_VERSION}"
python - "${TAG_VERSION}" <<'PY'
from pathlib import Path
import re
import sys

version = sys.argv[1].encode("ascii")
for filename, pattern, replacement in (
    ("WhisperMessenger.toc", rb"(?m)^## Version: [^\r\n]*", b"## Version: " + version),
    ("Core/Constants.lua", rb'VERSION = "[^"]*"', b'VERSION = "' + version + b'"'),
):
    path = Path(filename)
    data, count = re.subn(pattern, lambda _: replacement, path.read_bytes())
    if count != 1:
        raise SystemExit("Error: expected one version field in " + filename)
    path.write_bytes(data)
PY
python scripts/gen_patch_notes.py --version "${TAG_VERSION}"

# Only release metadata is staged; this script never pushes anything.
git add WhisperMessenger.toc Core/Constants.lua Core/PatchNotes.lua CHANGELOG.md archive/changelog
if ! git diff --cached --quiet; then
  git commit -m "release: ${TAG_VERSION}"
fi
git tag -a "${TAG_VERSION}" -m "Release ${TAG_VERSION}"

echo "Created local release ${TAG_VERSION}; Interface remains 30300."
echo "Publish the prepared commit and tag when ready:"
echo "  git push origin HEAD ${TAG_VERSION}"
echo "The tag workflow runs validation and publishes the installable ZIP to this GitHub fork."
echo "A manual workflow run only packages the selected ref as a workflow artifact."
