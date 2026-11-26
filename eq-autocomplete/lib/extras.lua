--[[
  Hand-made additions on top of the generated lib/commands.lua (which only knows what the RedGuides
  docs say). Edit freely; nothing here is overwritten by tools/build_commands.py.

  commands  new commands, or grammar lines added to existing ones (same format as commands.lua)
  sources   which list of live values fills a placeholder: by placeholder name, and per command
  common    commands to rank a little higher before any usage has been learned
]]
local M = {}

local opt = function(...) return { alt = { { ... } }, o = 1 } end

M.commands = {
    -- this script's own command
    ['/eqac'] = {
        p = 'MacroQuest', d = 'eq-autocomplete: this box.',
        s = { '/eqac [show | hide]', '/eqac key <combo> | off' },
        g = {
            { { alt = { { 'show' }, { 'hide' } }, o = 1 } },
            { 'key', { alt = { { 'shift+/' }, { 'off' }, { { v = 'keycombo' } } }, o = 1 } },
        },
    },
    -- MQ2Lua is not on the docs pages the list is built from
    ['/lua'] = {
        p = 'MacroQuest', d = 'Runs and manages Lua scripts.',
        s = { '/lua run <script> [args]', '/lua stop [<script>]', '/lua pause [<script>]', '/lua info [<script>]',
            '/lua list', '/lua ps', '/lua parse <lua code>', '/lua conf <setting> [<value>]', '/lua reloadconf', '/lua gui' },
        g = {
            { 'run', { v = 'script' }, opt({ v = 'args' }) },
            { 'stop', opt({ v = 'running script' }) },
            { 'pause', opt({ v = 'running script' }) },
            { 'info', opt({ v = 'running script' }) },
            { 'list' }, { 'ps' }, { 'parse', { v = 'lua code' } },
            { 'conf', { v = 'setting' }, opt({ v = 'value' }) }, { 'reloadconf' }, { 'gui' },
        },
    },
    -- '/nav spawn <search>' and '/nav id <n>' are what people type; the docs show only <spawn search>
    ['/navigate'] = {
        g = {
            { 'spawn', { v = 'spawn search' }, opt({ v = 'options' }) },
            { 'id', { v = 'spawnid' }, opt({ v = 'options' }) },
            { 'locxyz', { v = 'coordinates' } }, { 'locyx', { v = 'coordinates' } },
        },
    },
    -- MacroQuest's own target command (EverQuest's /target takes only a name or "group <1-6>")
    ['/mqtarget'] = {
        g = { { 'clear' }, { 'myself' }, { 'mycorpse' }, { 'id', { v = 'spawnid' } }, { 'npc' }, { 'pc' }, { 'corpse' },
            { { v = 'spawn search' } } },
    },
    ['/stick'] = {
        g = { { { alt = {
            { 'off' }, { 'id', { v = 'spawnid' } }, { 'behind' }, { 'behindonce' }, { 'front' }, { '!front' },
            { 'pin' }, { 'snaproll' }, { 'hold' }, { 'moveback' }, { 'loose' }, { 'uw' }, { 'pause' }, { 'unpause' },
            { 'reset' }, { 'set' }, { 'toggle' }, { { v = 'distance' } },
        }, o = 1, r = 1 } } },
    },
    ['/afollow'] = {
        g = { { { alt = { { 'on' }, { 'off' }, { 'pause' }, { 'unpause' }, { 'slow' }, { 'fast' } } } } },
    },
}

-- Placeholder name (lower case) -> source. Names not listed get no live values, only what you
-- have typed there before.
M.sources = {
    ['name'] = 'names', ['playername'] = 'names', ['player'] = 'names', ['player name'] = 'names',
    ['charname'] = 'names', ['character'] = 'names', ['character name'] = 'names', ['pc name'] = 'names',
    ['role/name'] = 'names', ['name | class | race'] = 'names', ['character to add'] = 'names',
    ['character to remove'] = 'names', ['target'] = 'names', ['peer'] = 'names', ['client'] = 'names',
    ['spawn search'] = 'spawns', ['spawnsearch'] = 'spawns', ['spawn'] = 'spawns', ['spawnname'] = 'spawns',
    ['spawn_name'] = 'spawns', ['search string'] = 'spawns', ['spawnfilter'] = 'spawns',
    ['spell name'] = 'spells', ['spellname'] = 'spells', ['song'] = 'spells', ['song name'] = 'spells',
    ['slot# | spellname'] = 'spells',
    ['item'] = 'items', ['itemname'] = 'items', ['item name'] = 'items', ['"itemname"|id'] = 'items',
    ['ability'] = 'abilities', ['skill name'] = 'abilities', ['skillname'] = 'abilities',
    ['discipline name'] = 'discs',
    ['buff name'] = 'buffs', ['name of buff'] = 'buffs',
    ['script'] = 'scripts', ['running script'] = 'running',
    ['group'] = 'dngroups',
    ['zonename'] = 'zones', ['zone'] = 'zones',
    ['aliasname'] = 'aliases',
}

-- Per command, by placeholder name: overrides M.sources (false = no live values).
M.commandSources = {
    ['/plugin'] = { ['name'] = 'plugins' },
    ['/macro'] = { ['filename'] = 'macros' },
    ['/navigate'] = { ['name'] = false },        -- waypoint names
    ['/bind'] = { ['name'] = false },
    ['/keypress'] = { ['name'] = false },
    ['/loadspells'] = { ['name'] = false },      -- spell set names
    ['/alternateadv'] = { ['id | name'] = false },
    ['/target'] = { ['name'] = 'spawns', ['option'] = false },
    ['/removebuff'] = { ['name'] = 'buffs' },
    ['/blockspell'] = { ['name'] = false },
}

-- A small head start before usage is learned: these rank above other commands sharing a prefix.
M.common = {
    '/target', '/tell', '/say', '/gsay', '/navigate', '/lua', '/dexecute', '/dgexecute', '/dgaexecute',
    '/dggexecute', '/dgzexecute', '/echo', '/cast', '/stick', '/useitem', '/invite', '/follow', '/assist',
    '/camp', '/loot', '/attack', '/sit', '/stand', '/who', '/consider', '/alternateadv', '/discipline',
    '/macro', '/plugin', '/endmacro', '/mqpause', '/squelch', '/afollow', '/travelto', '/reply', '/guildsay',
    '/raidsay', '/autoinventory', '/keypress', '/notify', '/memspell', '/loadspells', '/doability',
    '/removebuff', '/hidecorpse', '/disband', '/makemevisible', '/mqclear', '/timed', '/noparse',
}

return M
