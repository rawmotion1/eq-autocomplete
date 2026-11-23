-- Offline tests for the tokenizer, grammar walker, engine and learning (tests\run.ps1 runs this).
-- The game is replaced by a fake `sources` object; ImGui (lib/ui.lua) is not tested here.
local grammar = require('eq-autocomplete.lib.grammar')
local Engine = require('eq-autocomplete.lib.engine')
local Learn = require('eq-autocomplete.lib.learn')
local commands = require('eq-autocomplete.lib.commands')
local extras = require('eq-autocomplete.lib.extras')

local passed, failed = 0, 0
local function check(name, ok, detail)
    if ok then
        passed = passed + 1
        print('PASS: ' .. name)
    else
        failed = failed + 1
        print('FAIL: ' .. name .. (detail and ('  -- ' .. tostring(detail)) or ''))
    end
end

local function words(items, n)
    local out = {}
    for i = 1, math.min(#items, n or #items) do out[#out + 1] = items[i].w end
    return table.concat(out, ', ')
end
local function has(items, w)
    for _, it in ipairs(items) do if it.w == w then return true end end
    return false
end

local out = (os.getenv('EQAC_OUT') or '.'):gsub('\\', '/')
local clock = 1000000
local function now() return clock end

local fake = {
    version = 0,
    lists = {
        names = { { w = 'Aldric', d = 'logged in (DanNet)', b = 6 }, { w = 'Brenna', d = 'logged in (DanNet)', b = 6 } },
        spawns = { { w = 'Aldric', b = 14 }, { w = 'Brenna', b = 14 }, { w = 'a large rat', d = 'NPC, 20 away', b = 5 } },
        scripts = { { w = 'rgmercs' }, { w = 'boxhud' }, { w = 'eq-autocomplete' } },
        spells = { { w = 'Spirit of the Wolf', d = 'gem 1' }, { w = 'Spiritual Light', d = 'gem 2' } },
        plugins = { { w = 'MQ2Nav' }, { w = 'MQ2DanNet' } },
        zones = { { w = 'guildlobby', d = 'The Guild Lobby', m = 'The Guild Lobby' },
            { w = 'poknowledge', d = 'The Plane of Knowledge', m = 'The Plane of Knowledge' } },
    },
    loaded = { MQ2Nav = true, MQ2DanNet = true, MQ2MoveUtils = true, MQ2EasyFind = true },
}
function fake:get(kind) return self.lists[kind] or {} end
function fake:pluginLoaded(n) return self.loaded[n] == true end
function fake:macroRunning() return false end
function fake:classShort() return 'SHD' end
function fake:aliases()
    -- the CWTN convention: broadcast, and each character runs its own class command
    return { ['/t'] = '/tell', ['/w'] = '/who', ['/cwtn'] = '/dgge /docommand /$\\{Me.Class.ShortName}' }
end

local learn = Learn.new({ dir = out, me = 'test_aldric', now = now })
local engine = Engine.new({ commands = commands, extras = extras, learn = learn, sources = fake, now = now })
-- what lib/cwtn.lua builds from a CWTN plugin, in miniature
local ON_OFF = { alt = { { 'on' }, { 'off' } }, o = 1 }
engine:addCommand('/shd', {
    p = 'MacroQuest', d = 'CWTN class plugin MQ2Test', s = { '/shd <setting> [on | off | value]' },
    g = {
        { { k = 'mode', d = 'action' }, { alt = { { { k = 'tank', d = 'mode' } }, { { k = 'assist', d = 'mode' } } }, o = 1 } },
        { { k = 'pause', d = 'action' }, ON_OFF },
        { { k = 'UseLifeTap', d = 'setting, now true' }, ON_OFF },
    },
})

local function suggest(text, cursor) return engine:suggest(text, cursor or #text) end

-- tokenizer --------------------------------------------------------------------------------
do
    local t = grammar.tokenize('/cast "Spirit of the Wolf" now')
    check('tokenize: quoted words are one token', #t == 3 and t[2].value == 'Spirit of the Wolf' and t[2].quoted,
        #t .. ' tokens')
    local done, cur = grammar.split('/nav sp', 7)
    check('split: current word', #done == 1 and cur.value == 'sp' and cur.s == 6, cur.value .. ' at ' .. cur.s)
    done, cur = grammar.split('/nav ', 5)
    check('split: after a space the current word is empty', #done == 1 and cur.value == '' and cur.s == 6)
    done, cur = grammar.split('/cast "Spir', 11)
    check('split: an open quote is the current word', cur.open and cur.value == 'Spir' and cur.s == 7)
end

-- commands ---------------------------------------------------------------------------------
do
    local r = suggest('/na')
    check('commands: /na offers /nav and /navigate', has(r.items, '/nav') and has(r.items, '/navigate'), words(r.items, 6))
    r = suggest('/nav')
    check('commands: a fully typed command comes first', r.items[1] and r.items[1].w == '/nav', words(r.items, 3))
    local text, cursor = Engine.apply('/nav', r, r.items[1])
    check('commands: completing it adds a space', text == '/nav ' and cursor == 5, text)
    r = suggest('/dps')
    check('commands: a plugin that is not loaded is left out', not has(r.items, '/dpsadv'), words(r.items, 5))
    r = suggest('na')
    check('commands: typed without the slash still matches', has(r.items, '/navigate'), words(r.items, 4))
    text = Engine.apply('na', r, r.items[1])
    check('commands: and completes with the slash', text:sub(1, 1) == '/', text)
    r = suggest('')
    check('commands: nothing on an empty line', #r.items == 0)
    r = suggest('/')
    local firstCmd = r.items[1] and (engine.alias[r.items[1].w] or r.items[1].w)
    check('commands: a bare slash lists commands, common ones first', engine.common[firstCmd] == true, words(r.items, 5))
    r = suggest('/t')
    check('commands: MacroQuest.ini aliases are offered', has(r.items, '/t'), words(r.items, 8))
end

-- arguments --------------------------------------------------------------------------------
do
    local r = suggest('/nav ')
    check('args: /nav offers its keywords', has(r.items, 'spawn') and has(r.items, 'target') and has(r.items, 'loc'),
        words(r.items))
    r = suggest('/nav spawn ')
    check('args: /nav spawn offers my characters', has(r.items, 'Aldric') and has(r.items, 'Brenna'), words(r.items))
    check('args: characters rank above other spawns', r.items[1].w == 'Aldric' or r.items[1].w == 'Brenna',
        words(r.items))
    r = suggest('/nav spawn Al')
    check('args: prefix narrows to Aldric', r.items[1] and r.items[1].w == 'Aldric', words(r.items))
    check('args: ghost text is the rest of the name', Engine.ghost('/nav spawn Al', 13, r, r.items[1]) == 'dric')
    local text = Engine.apply('/nav spawn Al', r, r.items[1])
    check('args: completion replaces the word', text == '/nav spawn Aldric ', text)
    r = suggest('/nav ')
    check('args: hand-added keywords lead (/nav spawn first)', r.items[1] and r.items[1].w == 'spawn', words(r.items, 4))
    r = suggest('/nav spawn "a la')
    check('args: quoted spawn name', has(r.items, 'a large rat'), words(r.items))
    text = Engine.apply('/nav spawn "a la', r, r.items[1])
    check('args: quoted completion closes the quote', text == '/nav spawn "a large rat" ', text)

    r = suggest('/tell ')
    check('args: /tell offers characters', has(r.items, 'Aldric'), words(r.items))
    r = suggest('/t Br')
    check('args: an ini alias (/t = /tell) uses /tell\'s syntax', has(r.items, 'Brenna'), words(r.items))
    r = suggest('/msg ')
    check('args: a docs abbreviation (/msg) uses /tell\'s syntax', has(r.items, 'Aldric'), words(r.items))
    r = suggest('/tell Aldric hel')
    check('args: nothing to suggest inside a message', #r.items == 0, words(r.items))

    r = suggest('/dex ')
    check('args: /dex offers characters', has(r.items, 'Aldric'), words(r.items))
    r = suggest('/dex Aldric /nav sp')
    check('nested: /dex Name /nav completes /nav\'s keywords', r.items[1] and r.items[1].w == 'spawn', words(r.items))
    text = Engine.apply('/dex Aldric /nav sp', r, r.items[1])
    check('nested: completion lands in the right place', text == '/dex Aldric /nav spawn ', text)
    r = suggest('/dex Aldric /na')
    check('nested: the command word itself', has(r.items, '/nav'), words(r.items, 5))

    r = suggest('/lua run rg')
    check('args: /lua run offers scripts', r.items[1] and r.items[1].w == 'rgmercs', words(r.items))
    r = suggest('/cast "Spi')
    check('args: /cast offers gem spells', has(r.items, 'Spirit of the Wolf'), words(r.items))
    text = Engine.apply('/cast "Spi', r, r.items[1])
    check('args: spell with spaces is quoted', text == '/cast "Spirit of the Wolf" ' or text == '/cast "Spiritual Light" ',
        text)
    r = suggest('/eqac key ')
    check('args: the box completes its own /eqac', has(r.items, 'shift+/') and has(r.items, 'off'), words(r.items))
    r = suggest('/plugin mq2n')
    check('args: /plugin offers plugin files', has(r.items, 'MQ2Nav'), words(r.items))

    -- completing in the middle of a line
    r = suggest('/nav sp Aldric', 7)
    text = Engine.apply('/nav sp Aldric', r, r.items[1])
    check('middle: replaces only the word at the cursor', text == '/nav spawn Aldric', text)
end

-- CWTN class command and zones -------------------------------------------------------------
do
    local r = suggest('/sh')
    check('cwtn: the class command is offered', has(r.items, '/shd'), words(r.items, 6))
    r = suggest('/shd ')
    check('cwtn: actions first', r.items[1] and r.items[1].w == 'mode', words(r.items))
    local lifetap
    for _, it in ipairs(r.items) do if it.w == 'UseLifeTap' then lifetap = it end end
    check('cwtn: settings show their value', lifetap and lifetap.d == 'setting, now true', lifetap and lifetap.d)
    r = suggest('/shd mode ')
    check('cwtn: mode names', has(r.items, 'tank') and has(r.items, 'assist'), words(r.items))
    r = suggest('/shd uselife')
    check('cwtn: settings complete case-insensitively', r.items[1] and r.items[1].w == 'UseLifeTap', words(r.items))
    r = suggest('/cwtn ')
    check('cwtn: an alias through /dgge /docommand /${Me.Class.ShortName} completes as /shd', has(r.items, 'mode'),
        words(r.items))
    r = suggest('/cwtn pause ')
    check('cwtn: and its arguments', has(r.items, 'on') and has(r.items, 'off'), words(r.items))
    r = suggest('/dgge /shd mo')
    check('cwtn: nested after /dgge', r.items[1] and r.items[1].w == 'mode', words(r.items))

    r = suggest('/travelto ')
    check('zones: /travelto offers zone short names', has(r.items, 'poknowledge') and has(r.items, 'guildlobby'),
        words(r.items))
    r = suggest('/travelto knowl')
    check('zones: matched by long name too', r.items[1] and r.items[1].w == 'poknowledge', words(r.items))
    local text = Engine.apply('/travelto knowl', r, r.items[1])
    check('zones: completes the short name', text == '/travelto poknowledge ', text)
end

-- learning ---------------------------------------------------------------------------------
do
    for _ = 1, 3 do engine:record('/nav spawn Brenna') end
    local r = suggest('/nav spawn ')
    check('learn: the most used name comes first', r.items[1] and r.items[1].w == 'Brenna', words(r.items))

    for _ = 1, 5 do engine:record('/stick behind') end
    r = suggest('/st')
    check('learn: the most used command comes first', r.items[1] and r.items[1].w == '/stick', words(r.items, 4))

    engine:record('/tell Aldric hello there')
    check('learn: message words are not learned', next(learn:argsFor('/tell', 2, 'aldric')) == nil)
    check('learn: the name before the message is', learn:argsFor('/tell', 1, '')['aldric'] ~= nil)

    engine:record('/rgl pause')
    engine:record('/rgl pause')
    r = suggest('/rg')
    check('learn: unknown commands are learned', has(r.items, '/rgl'), words(r.items, 5))
    r = suggest('/rgl ')
    check('learn: and their arguments', r.items[1] and r.items[1].w == 'pause', words(r.items))

    engine:record('/dex Brenna /nav spawn Aldric')
    check('learn: a nested command is learned as itself', learn:argsFor('/navigate', 2, 'spawn')['aldric'] ~= nil)

    local lines = learn:lines()
    check('learn: lines are kept for recall, newest last', lines[#lines] == '/dex Brenna /nav spawn Aldric',
        lines[#lines])
    local before = #lines
    engine:record('/nav spawn Brenna')
    check('learn: a repeated line moves to the end, not duplicated', #learn:lines() == before - 0 and
        learn:lines()[#learn:lines()] == '/nav spawn Brenna', #learn:lines())
end

-- files ------------------------------------------------------------------------------------
do
    learn.own.args['x|1|'] = { ['end'] = { n = 1, t = 1, w = 'end' }, ['a"b'] = { n = 2, t = 2, w = 'a"b' } }
    learn.dirty = true
    check('files: save', learn:save())
    local back = Learn.readFile(learn:ownPath())
    check('files: reads back what was saved', back and back.cmds['/stick'] and back.cmds['/stick'].n == 5)
    check('files: keys that are Lua words survive', back and back.args['x|1|']['end'] and back.args['x|1|']['a"b'].n == 2)

    local other = Learn.new({ dir = out, me = 'test_brenna', now = now })
    other:load(function()
        return { 'learned_test_aldric.lua', 'learned_test_brenna.lua', 'settings.lua' }
    end)
    check('files: another character reads this one\'s usage', other:commands()['/stick'] and other:commands()['/stick'].n == 5)
    check('files: but keeps its own lines', #other:lines() == 0)
    check('files: a broken file reads as nothing', Learn.readFile(out .. '/does-not-exist.lua') == nil)
end

-- the whole command list -------------------------------------------------------------------
do
    local n, broken = 0, {}
    for name, c in pairs(engine.db) do
        n = n + 1
        local ok, err = pcall(grammar.walk, c.g, { 'x', 'y', 'z' })
        if not ok then broken[#broken + 1] = name .. ': ' .. tostring(err) end
        ok, err = pcall(function() engine:suggest(name .. ' ', #name + 1) end)
        if not ok then broken[#broken + 1] = name .. ': ' .. tostring(err) end
    end
    check('db: every command walks without error (' .. n .. ')', #broken == 0, table.concat(broken, '; '))
end

print(string.format('RESULT: %d passed, %d failed', passed, failed))
