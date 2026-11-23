# eq-autocomplete

A floating command box for MacroQuest. Type a command and it suggests the rest as you go:
commands, their keywords, and live values such as your other logged-in characters, nearby
spawns, memorized spells, clickies, zones and Lua scripts. It learns what you type most and ranks
that first. Enter sends the line to MacroQuest, as if typed in the MQ console.

```
/lua run eq-autocomplete
```

Put this folder in MacroQuest's `lua` folder as `eq-autocomplete` (a copy, or a junction to a clone).

## Keys

| Key | What it does |
| --- | --- |
| Tab | Complete the word with the highlighted suggestion (adds a space at the end of the line) |
| Right arrow | The same, when the cursor is already at the end of the line |
| Up / Down | Move through the suggestions. With none showing, step through lines you sent before |
| Enter | Send the line. A line without a leading `/` gets one |
| Escape | Clear the line; press again to leave the box |

The highlighted suggestion shows as grey text after the cursor. Clicking a suggestion also
completes it. Under the list is the command's syntax as documented, so you can see what comes next.

The `::` grip on the left moves the box; drag its right edge to resize. Right-click the grip for
options: keep focus after Enter, show syntax, lock position, number of rows, hide.

## Commands

| Command | |
| --- | --- |
| `/eqac` | Show or hide the box |
| `/eqac focus` | Show it and put the cursor in it |
| `/eqac slash` | The same, on a fresh line starting with `/` |
| `/eqac key shift+/` | Make a key (any combo) open the box with `/` typed. `/eqac key off` undoes it; `/eqac key` says what is set |
| `/eqac reload` | Re-read aliases, scripts, plugins and the other characters' usage now |
| `/eqac forget` | Forget what was learned on this character |
| `/eqac stop` | Close it |

## Open it with a key

`/eqac key shift+/` makes shift+/ open the box on a fresh line starting with `/`. Any MacroQuest
key combo works (`ctrl+/`, `shift+enter`...). `/eqac key off` removes it, and `/eqac key` says
what is set. It prints each command it runs, with MacroQuest's replies, then reads the saved
binds back and says whether they were saved.

How it works: a custom bind (MQ2CustomBinds) named `eqac` is put on the key. Its command checks
whether the script is running: if it is, it opens the box (`/eqac slash`); if it isn't, it starts
it (`/lua run eq-autocomplete slash`). Plain `/` also belongs to MQ2ChatWnd's bind `MQ2CSCHAT`, so
choosing `/` clears that bind (and `off` restores it); other keys leave it alone. In practice
EverQuest still opens its chat on plain `/`, so use a combination such as shift+/.

The binds are saved for all characters, but a game window reads them only when it starts. Every
running copy of the script follows the setting within 10 seconds; game windows without the script
pick it up when they restart. The key does nothing to a line you are already typing in the box.

## What it suggests

- **Commands**: about 670 EverQuest, MacroQuest and plugin commands from the RedGuides docs, plus
  their documented abbreviations (`/nav`, `/dex`, `/dgge`...) and your aliases from `MacroQuest.ini`.
  Plugin commands only show when the plugin is loaded (KissAssist's only while it runs).
- **Keywords**: what each command's syntax allows at that point, e.g. `/nav` then `spawn`, `target`, `loc`...
- **Live values**, picked by what the syntax expects there:
  - characters: your logged-in characters (DanNet peers, EQBC if connected), group and raid members.
    `/tell`, `/dex`, `/invite`, `/assist`, `/bct`...
  - spawns: your characters first, then the nearest NPCs and PCs. `/nav spawn`, `/target`
  - zones: short names from the Magellan script's travel list when it is installed (else every
    zone MacroQuest knows), matched on the long name too:
    `/travelto knowl` offers `poknowledge`.
  - spells in your gems (`/cast`), clickies you carry (`/useitem`), combat abilities (`/disc`),
    buffs (`/removebuff`), abilities (`/doability`)
  - Lua scripts (`/lua run`), running scripts (`/lua stop`), macros (`/mac`), plugins (`/plugin`),
    DanNet groups (`/dgt`, `/dgae`)
- **CWTN class plugins**: on a character running one (MQ2Shaman, MQ2Bard, MQ2EsKay...), its class
  command (`/shm`, `/brd`, `/shd`...) with every action (`mode`, `pause`, `burnnow`, `toggleui`...)
  and setting (`UseMelee`, `CampRadius`...), each showing its current value, and the mode names.
  Read at start from the plugin and the character's `config\CWTN\<Plugin>_<Name>.ini`. An alias
  that broadcasts the class command, like `/cwtn = /dgge /docommand /$\{Me.Class.ShortName}`,
  completes the same way.
- **Nested commands**: after `/dex Name`, `/dgge`, `/timed 10`, `/squelch`, `/noparse` and the like,
  the rest of the line is completed as a command of its own: `/dex Bob /nav spawn Alice`.
- **What you typed before**: every argument is remembered in its place (command, position, the word
  before it), so commands the docs don't know about (`/rgl pause`) get suggestions too. Free text
  such as a `/tell` message is not learned word by word.

## Learning, and where your data lives

Each line you send counts toward its command and each argument. Suggestions you use often, and
recently, move up. Each character writes its own file and reads everyone's, so what you type on
one character ranks suggestions on all of them (re-read every minute). The last 300 lines are kept
per character for Up/Down recall.

All of it stays in MacroQuest's config folder, never in this folder:
`<MacroQuest>\config\eq-autocomplete\`

- `learned_<server>_<name>.lua`: one character's usage and recent lines
- `settings.lua`: box options and the opening key (shared)
- `cwtn_cache.lua`: what was read from CWTN plugin files (rebuilt when a plugin changes)

## Changing what it knows

- `lib\commands.lua` is generated from the RedGuides pages:
  `python tools\build_commands.py` (uses the copies in `tools\cache\`, downloading any missing),
  or `python tools\build_commands.py --refresh` to download them again.
- `lib\extras.lua` is hand-written and survives a rebuild: commands the docs lack (`/lua`),
  keywords people really type (`/nav spawn`, `/stick behind`), which placeholder gets which live
  list, and the commands that rank higher before anything is learned.

## Tests

```
powershell -NoProfile -ExecutionPolicy Bypass -File tests\run.ps1     # engine, grammar, learning, offline
powershell -NoProfile -ExecutionPolicy Bypass -File tests\check.ps1   # type check against ..\mq-definitions
```

Both use the Lua language server from the VS Code Lua extension; no Lua install needed. The type
check expects [mq-definitions](https://github.com/macroquest/mq-definitions) next to this folder.
The offline tests run on a newer Lua than MacroQuest's LuaJIT and can't reach ImGui, so
`lib\ui.lua` is covered only by the type check.

## Status

- Works in game: the box, sending lines, learning, the opening key (shift+/).
- Checked in game with read-only probes: the live lists' TLO calls, the opening key's check
  (running vs not), the CWTN reader (one SHD character: 141 actions and settings, 9 modes) and
  the Magellan zone list (605 zones).
- Not yet confirmed in game: CWTN and zone suggestions inside the box, the `/cwtn`-style alias.
