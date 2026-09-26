# WhisperMessenger — WotLK Backport

A backport of [F0rty-Tw0's WhisperMessenger](https://github.com/F0rty-Tw0/WhisperMessenger)
for the **original World of Warcraft: Wrath of the Lich King 3.3.5a client**
(build 12340, interface 30300), including Frostmourne/Rebuffed.

Maintained in [JGoldz75's fork](https://github.com/JGoldz75/WhisperMessenger-WotLK-Backport-).
The first backport release is **2.0.2**, based on upstream **2.0.1**. This package
is for the original client; use upstream for Retail or modern Classic clients.

## Features

- One messenger window with separate conversations, chat bubbles, unread badges,
  saved history, contact search, nicknames, notes, and pinned chats.
- Character whispers and party, raid, guild, and battleground conversations.
- Themes, the Native WoW HUD option, notifications, drafts, and quick replies.
- Automatic opening on incoming whispers, with an **Only auto-open outside combat**
  option under **Options > Behavior**. Combat protection is enabled by default
  and affects the main window; small preview popups keep their existing behavior.
- Quoted replies, reactions, typing indicators, and read receipts between players
  running compatible copies.
- Original-client menus, clickable chat links, portable artwork, and bundled
  class icons that work with Frostmourne/Rebuffed's custom textures.
- No extra compatibility addon required; can coexist with ClassicAPI.

Battle.net whispers, communities, and cross-game chat are unavailable on the
original client. Unknown player status is left unknown when the client has no
information. Class portraits are square, and sounds follow your game audio settings.

## Install

1. Download the [source ZIP](https://github.com/JGoldz75/WhisperMessenger-WotLK-Backport-/archive/refs/heads/master.zip)
   or a packaged ZIP from [Releases](https://github.com/JGoldz75/WhisperMessenger-WotLK-Backport-/releases), when available.
2. Exit WoW. If using the source ZIP, rename the extracted repository folder to
   exactly **WhisperMessenger**.
3. Put that folder in `Interface\AddOns`. The file must be at
   `Interface\AddOns\WhisperMessenger\WhisperMessenger.toc`, without an extra nested folder.
4. Start the game, enable the addon, and type **`/wmsg`**.

For an existing installation, replace the addon files and run `/reload`.
Keep the folder name `WhisperMessenger`; texture paths depend on it. Saved chat
history and settings are preserved. Do not install a second copy under a different name.

Open **Options > What's New** in the addon for this version's changes, or read the
[full changelog](CHANGELOG.md). More compatibility details and a live-client
checklist are in [README-WOTLK.md](README-WOTLK.md).

## Development

The runtime uses Lua 5.1. From the repository root:

```sh
python -m pip install lupa
python scripts/verify_wotlk.py
python -m unittest tests.scripts.test_gen_patch_notes tests.scripts.test_promote_changelog
bash scripts/lint.sh
python scripts/package_wotlk.py
```

The package is written to `dist/WhisperMessenger-<version>-WotLK-3.3.5a.zip`,
containing the correctly named `WhisperMessenger` folder and runtime files only.
The GitHub CI workflow validates the port and builds a downloadable package artifact.
The manual packaging workflow also produces an artifact; version tags publish
GitHub Releases. The fork does not publish packages to the upstream project's
CurseForge or Wago listings.

## Credits and support

Original addon by **F0rty_tw0**, distributed under the [MIT license](LICENSE).
The upstream source and author attribution are preserved. Blizzard class artwork
is credited in [Media/class-icons-attribution.txt](Media/class-icons-attribution.txt).

When reporting a backport problem, include your client build, server, other
addons, and the first Lua error if one appears.
