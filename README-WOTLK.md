# WhisperMessenger for original Wrath 3.3.5a

This is JGoldz75's backport of [F0rty-Tw0's WhisperMessenger](https://github.com/F0rty-Tw0/WhisperMessenger)
v2.0.1, based on upstream commit `5589569632f447e9921a6d129cc02ae44fbda85a`.
Backport source, updates, and issues:
[WhisperMessenger WotLK Backport](https://github.com/JGoldz75/WhisperMessenger-WotLK-Backport-).

Target: the original World of Warcraft 3.3.5a client, build 12340, interface
30300, including the Frostmourne/Rebuffed installation. This is not a Wrath
Classic (3.4.x) package and is not an official upstream release.

## Install and open

1. Exit WoW completely.
2. Extract the `WhisperMessenger` folder to `Interface\AddOns`.
3. Start WoW and enable WhisperMessenger on the character selection AddOns screen.
4. Log in and type `/wmsg`. The window also has a floating icon and minimap option.

When installing from GitHub's source ZIP, rename the extracted repository folder
to exactly `WhisperMessenger` before moving it to `Interface\AddOns`. The addon
files must sit directly inside that folder, without another folder in between.
Restart the game after a first installation; `/reload` is enough for updates to
an already discovered addon.

To open the main window automatically when someone whispers you, turn on
**Options > Behavior > Auto-open on incoming whisper**. Leave **Only auto-open
outside combat** enabled to avoid interruptions during fights. Small message-preview
popups keep their existing settings, and you can still open the messenger manually.

## What the port preserves

- The original messenger window, themes, chat bubbles, contact search, unread
  counts, notifications, drafts, saved history, and settings.
- Character whisper sending and receiving, replies, item/quest links, and the
  addon's existing reactions, typing indicators, and read receipts between users
  running compatible copies.
- Friends and party/raid/guild information available from the original client.
- Group chats, with original battleground chat mapped into the instance chat view.

The compatibility code is private to WhisperMessenger. It does not replace
Blizzard's global APIs or require `!!!ClassicAPI`.

## Original-client differences

- Private servers do not provide Blizzard Battle.net accounts, communities,
  cross-game whispers, or modern remote-player availability queries. Character
  whispers remain available. A stranger's status may be unknown until the client
  supplies information; unknown does not mean offline.
- The original artwork ships as uncompressed TGA with the same pixels and alpha.
  Original-client substitutes are used where newer Blizzard textures or widget
  effects are unavailable. Class portraits use individual bundled class images
  so custom client texture sheets cannot distort them. They remain square because
  the original engine lacks modern texture masking.
- Notification sounds use original-client sound names. Newer sound choices fall
  back to the whisper sound. Notifications follow the original client's audio
  settings and cannot promise playback when game audio is disabled.
- Retail's Mythic+/competitive whisper restrictions do not apply to this client.
- The port preserves the upstream saved-variable names. Do not install a second
  copy under a different addon directory name.

## Validation and in-game check

Run `python scripts/verify_wotlk.py` from the source checkout with Python and
`lupa` installed. It uses Lua 5.1, compiles every manifest file, and runs the
upstream tests plus original-client regressions. A strict simulated original
client checks loading and user flows without modern APIs.

The main messenger window and two-way character whispers have also been checked
in Frostmourne/Rebuffed. Offline tests cannot confirm every rendering detail,
game-server interaction, or combination of other addons. To check your client:

1. Open `/wmsg`, switch themes, resize the window, and open settings.
2. Exchange a character whisper with another player; verify both directions.
3. Reply using the composer, click an item link, and open a contact's context menu.
4. Reload the UI and confirm the conversation history remains.
5. If available, test typing/read receipts with another copy of this port.

If a Lua error occurs, enable `/console scriptErrors 1`, restart, and capture the
first new error including its file and line number.

## Remove or restore

Exit WoW, then disable WhisperMessenger or remove only
`Interface\AddOns\WhisperMessenger`. Saved history remains in the account and
character `SavedVariables` folders until you choose to remove it. Existing addon
folders and other saved variables are not part of this installation.

The upstream MIT license and author attribution are preserved in `LICENSE`.
