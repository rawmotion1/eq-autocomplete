# RedGuides resource page

Text for the resource's page on RedGuides. The description is BBCode: in the editor, switch to
BBCode mode (the `[ ]` button) and paste everything between the code fences.

- **Title:** eq-autocomplete
- **Version:** 0.3.0
- **Tagline:** A floating MacroQuest command box that autocompletes commands, keywords, character names, spawns and zones, and learns what you type most.

## Description

```bbcode
[HEADING=2]What it is[/HEADING]
A small floating command box for MacroQuest with autocomplete. Start typing a command and it suggests the rest: the command itself, the keywords its syntax allows next, and live values from the game such as your other characters, nearby spawns, zones, memorized spells, clickies and Lua scripts. Press [B]Tab[/B] to take a suggestion and [B]Enter[/B] to run the line. It learns which commands and arguments you use most and puts them first.

[HEADING=2]Features[/HEADING]
[LIST]
[*][B]About 670 commands[/B]: EverQuest, MacroQuest and plugin commands, built from the RedGuides command docs, with their documented abbreviations ([ICODE]/nav[/ICODE], [ICODE]/dex[/ICODE], [ICODE]/dgge[/ICODE]...) and your own aliases from MacroQuest.ini. Plugin commands only show up when the plugin is loaded.
[*][B]Knows what comes next[/B]: after [ICODE]/nav[/ICODE] it offers spawn, target, loc...; after [ICODE]/hidecorpse[/ICODE] its options. The command's syntax is shown under the list.
[*][B]Live values[/B], picked by what the command expects at that point:
[LIST]
[*]your logged-in characters (DanNet peers, EQBC), group and raid members: [ICODE]/tell[/ICODE], [ICODE]/dex[/ICODE], [ICODE]/invite[/ICODE], [ICODE]/assist[/ICODE], [ICODE]/bct[/ICODE]
[*]spawns, your characters first, then the nearest NPCs and PCs: [ICODE]/nav spawn[/ICODE], [ICODE]/target[/ICODE]
[*]zone short names from Magellan's travel list (or every zone MacroQuest knows), matched on the long name too: [ICODE]/travelto knowl[/ICODE] offers poknowledge
[*]spells in your gems ([ICODE]/cast[/ICODE]), clickies you carry ([ICODE]/useitem[/ICODE]), combat abilities ([ICODE]/disc[/ICODE]), buffs ([ICODE]/removebuff[/ICODE]), abilities ([ICODE]/doability[/ICODE])
[*]Lua scripts ([ICODE]/lua run[/ICODE]), running scripts ([ICODE]/lua stop[/ICODE]), macros ([ICODE]/mac[/ICODE]), plugins ([ICODE]/plugin[/ICODE]), DanNet groups ([ICODE]/dgt[/ICODE], [ICODE]/dgae[/ICODE])
[/LIST]
[*][B]Nested commands[/B]: after [ICODE]/dex Name[/ICODE], [ICODE]/dgge[/ICODE], [ICODE]/timed 10[/ICODE], [ICODE]/squelch[/ICODE], [ICODE]/noparse[/ICODE] and the like, the rest of the line completes as a command of its own: [ICODE]/dex Bob /nav spawn Alice[/ICODE]
[*][B]CWTN class plugins[/B]: on a character running one, its class command ([ICODE]/shm[/ICODE], [ICODE]/brd[/ICODE], [ICODE]/shd[/ICODE]...) with every action (mode, pause, burnnow, toggleui...) and every setting, each showing its current value, plus the mode names. Read when the script starts from the plugin and the character's CWTN ini; nothing from the plugins is bundled. An alias such as [ICODE]/cwtn = /dgge /docommand /$\{Me.Class.ShortName}[/ICODE] completes the same way.
[*][B]Learns from you[/B]: every argument is remembered in its place, so the names and commands you use most rise to the top, and commands the docs don't cover (like [ICODE]/rgl[/ICODE]) get suggestions too. What one character learns helps all your characters on the same PC.
[*][B]Hotkey[/B]: [ICODE]/eqac key shift+/[/ICODE] makes a key open the box with "/" already typed. If the script isn't running, the key starts it.
[/LIST]

[HEADING=2]Keys[/HEADING]
[LIST]
[*][B]Tab[/B], or [B]Right arrow[/B] at the end of the line: complete the word with the highlighted suggestion (shown in grey after the cursor)
[*][B]Up / Down[/B]: move through the suggestions; with none showing, step through lines you sent before
[*][B]Enter[/B]: run the line (a missing leading "/" is added)
[*][B]Escape[/B]: clear the line; press again to leave the box
[/LIST]
Drag the [B]::[/B] grip to move the box and its right edge to resize it. Right-click the grip for options: keep focus after Enter, show syntax, lock position, number of rows, hide.

[HEADING=2]Commands[/HEADING]
[CODE]/lua run eq-autocomplete
/eqac                  show or hide the box
/eqac focus            show it and put the cursor in it
/eqac slash            the same, on a fresh line starting with /
/eqac key shift+/      a key that opens the box with / typed (any key combo; "off" removes it)
/eqac reload           re-read aliases, scripts, plugins and usage now
/eqac forget           forget what was learned on this character
/eqac stop             close it[/CODE]

[HEADING=2]Installation[/HEADING]
Extract into your MacroQuest [ICODE]lua[/ICODE] folder so that you have [ICODE]lua\eq-autocomplete\init.lua[/ICODE], then [ICODE]/lua run eq-autocomplete[/ICODE].

[B]Requires[/B] MacroQuest. [B]Optional[/B]: MQ2DanNet (your characters' names), Magellan (zone list), MQ2CustomBinds (ships with MacroQuest; used for the hotkey), CWTN class plugins.

[HEADING=2]Your data[/HEADING]
Learned usage, recent lines and settings stay on your PC, in [ICODE]<MacroQuest>\config\eq-autocomplete\[/ICODE]: one file per character, read by all your characters. Nothing is sent anywhere. [ICODE]/eqac forget[/ICODE] clears a character's.

[HEADING=2]Notes[/HEADING]
[LIST]
[*]Plain "/" can't take over from EverQuest's chat (EverQuest opens its chat anyway), so give the hotkey a combination such as shift+/.
[*]Spawn names with spaces are inserted in quotes.
[*]Early release. Bug reports and commands it gets wrong are welcome in the discussion thread.
[/LIST]

[HEADING=2]Credits[/HEADING]
Command list and syntax from the RedGuides command documentation. Zone list from Magellan.
```
