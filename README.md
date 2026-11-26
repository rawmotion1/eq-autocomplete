# eq-autocomplete

A floating command box for MacroQuest with autocomplete. Start typing a command and it suggests
the rest: the command itself, the options its syntax allows next, and live values from the game
such as your other characters, nearby spawns, zones, memorized spells, clickies and Lua scripts.
Press Tab to take a suggestion and Enter to run the line. It learns which commands and arguments
you use most and puts them first.

## Installation

Copy the `eq-autocomplete` folder into your MacroQuest `lua` folder, so that you have
`lua\eq-autocomplete\init.lua`, then in game:

```
/lua run eq-autocomplete
```

**Requires** MacroQuest. **Optional:** MQ2DanNet or EQBC (your characters' names), Magellan (zone
list), MQ2CustomBinds (ships with MacroQuest; used for the hotkey, see below).

## What it knows

- **Every publicly listed EverQuest and MacroQuest command**, from the RedGuides command docs,
  including the plugins documented there (MQ2Nav, MQ2DanNet, MQ2MoveUtils...), with their
  documented abbreviations (`/nav`, `/dex`, `/dgge`...). A plugin's commands show up if the
  plugin is loaded when the script starts (KissAssist's and RGMercs' always do). A plugin loaded later shows
  up after the script is restarted.
- **Common commands for popular plugins and scripts.** I'm adding these over time. Already in:
  - the CWTN class plugins (`/shd`, `/shm`, `/brd`...), with the commands listed on each plugin's
    RedGuides page. Your own class's command comes first.
  - RGMercs (`/rgl`), with the commands it lists when you type `/rgl` in game (pull modes,
    assist and heal lists, chase and camp, pause...). Its settings (`/rgl set <setting>`) aren't
    listed.
- **Your aliases** from MacroQuest.ini, read when the script starts. An alias that wraps another command, like
  `/cwtn = /dgge /docommand /$\{Me.Class.ShortName}`, completes like the command it runs.
- **What comes next:** after `/nav` it offers `spawn`, `target`, `loc`...; after `/hidecorpse`
  its options. The command's syntax is shown under the list.
- **Live values**, picked by what the command expects at that point:
  - your logged-in characters, group and raid members: `/tell`, `/dex`, `/invite`, `/assist`, `/bct`
  - spawns within 100 units, after your own characters: `/nav spawn`, `/target`
  - zone short names from Magellan's travel list (or every zone MacroQuest knows), matched on the
    long name too: `/travelto knowl` offers `poknowledge`
  - spells in your gems (`/cast`), clickies you carry (`/useitem`), combat abilities (`/disc`),
    buffs (`/removebuff`), abilities (`/doability`)
  - Lua scripts (`/lua run`), running scripts (`/lua stop`), macros (`/mac`), plugins (`/plugin`),
    DanNet groups (`/dgt`, `/dgae`)
- **Nested commands:** after `/dex Name`, `/dgge`, `/timed 10`, `/squelch`, `/noparse` and the
  like, the rest of the line completes as a command of its own: `/dex Bob /nav spawn Alice`.
- **What you type:** every argument is remembered in its place, so the names and commands you use
  most rise to the top, and commands it doesn't know yet get suggestions too. Messages (the text
  of a `/tell`) are not remembered word by word.

## Keys

| Key | What it does |
| --- | --- |
| Tab | Complete the word with the highlighted suggestion |
| Right arrow | The same, when the cursor is at the end of the line |
| Up / Down | Move through the suggestions. With none showing, step through lines you sent before |
| Enter | Run the line (a missing leading `/` is added). If you moved to a suggestion with Up/Down, it is taken first |
| Escape | Clear the line; press again to leave the box |

The highlighted suggestion shows as grey text after the cursor, and clicking a suggestion also
completes it. Drag the `::` grip to move the box and its right edge to resize it. Right-click the
grip for options: keep focus after Enter, show syntax, lock position, number of rows, hide.

## Commands

| Command | |
| --- | --- |
| `/eqac` | Show or hide the box |
| `/eqac show` | Show it, ready to type on a fresh line starting with `/` |
| `/eqac hide` | Hide it |
| `/eqac key shift+/` | Make a key open the box ready to type (any key combination). `/eqac key off` removes it; `/eqac key` says what is set |

`/lua stop eq-autocomplete` closes it. What it learned is saved 5 seconds after the last line you
sent, so a line sent just before stopping may not be remembered.

You can camp and log in another character without restarting it: it saves when the character
leaves the world, hides the box at character select, and switches to the new character's learned
usage and settings when that one enters the world.

## Opening it with a key

`/eqac key shift+/` makes shift+/ open the box with `/` already typed. Any MacroQuest key
combination works (`ctrl+/`, `shift+enter`...). If the script isn't running, the key starts it.
Plain `/` can't be used: EverQuest opens its chat window on it anyway.

The key is a MacroQuest key bind, so MacroQuest saves it for all your characters. A game window
that is already running gets it the next time the script starts there.

The key uses MQ2CustomBinds. It ships with MacroQuest and is loaded by default; if you have
unloaded it, the script loads it when it needs it with `noauto`, for that session only, so your
list of plugins loaded at start stays as you set it. In that case the key works while the script
runs, but can only start the script if MQ2CustomBinds is loaded when the game starts.

## Your data

Each character keeps its own: what it learned and your recent lines in
`learned_<server>_<name>.lua`, and the box's options in `settings_<server>_<name>.lua`, both in
`<MacroQuest>\config\eq-autocomplete\` on your PC. Characters don't learn from each other, and you
can, say, lock the box on one and not on another. Nothing is sent anywhere. Delete a character's
files to start it over.

## Notes

- Spawn names with spaces are inserted in quotes.
- Bug reports, and commands it gets wrong or doesn't know, are welcome.
