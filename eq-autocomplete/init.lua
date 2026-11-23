--[[
  eq-autocomplete: a floating command box for MacroQuest that completes commands and arguments
  as you type, and learns which ones you use most.

    /lua run eq-autocomplete          (add "show" to open it ready to type)

    /eqac                show or hide the box
    /eqac show           show it, ready to type on a fresh line starting with "/"
    /eqac hide           hide it
    /eqac key shift+/    make a key open the box ready to type (any key combination; "off" removes it)

  Learned usage and settings live in <MacroQuest>\config\eq-autocomplete\.
]]
local args = { ... }
local mq = require('mq')
local Engine = require('eq-autocomplete.lib.engine')
local Learn = require('eq-autocomplete.lib.learn')
local Sources = require('eq-autocomplete.lib.sources')
local Ui = require('eq-autocomplete.lib.ui')
local Hotkey = require('eq-autocomplete.lib.hotkey')
local Cwtn = require('eq-autocomplete.lib.cwtn')
local commands = require('eq-autocomplete.lib.commands')
local extras = require('eq-autocomplete.lib.extras')

local VERSION = '0.4.0'

local function say(fmt, ...)
    print(string.format("\ag[eqac]\ax " .. fmt, ...))
end

-- data folder
local dataDir = mq.configDir .. '/eq-autocomplete'
do
    local ok, lfs = pcall(require, 'lfs')
    if ok and not lfs.attributes(dataDir) then lfs.mkdir(dataDir) end
end

local function tag()
    local server = tostring(mq.TLO.EverQuest.Server() or 'server')
    local name = tostring(mq.TLO.Me.CleanName() or 'unknown')
    return ((server .. '_' .. name):lower():gsub('[^%w_]', '_'))
end

local function listLearned(dir) return Sources.files(dir, '^learned_.*%.lua$') end

local learn = Learn.new({ dir = dataDir, me = tag() })
learn:load(listLearned)

-- settings (shared by all characters)
local settingsPath = dataDir .. '/settings.lua'
local settings = Learn.readFile(settingsPath) or {}
local defaults = { keepFocus = false, showSyntax = true, locked = false, rows = 8 }
for k, v in pairs(defaults) do
    if settings[k] == nil then settings[k] = v end
end
local function saveSettings()
    pcall(mq.pickle, settingsPath, settings)
end
-- another character may have changed them: take the file's values, keeping the same table
local function reloadSettings()
    local fresh = Learn.readFile(settingsPath)
    if fresh then for k, v in pairs(fresh) do settings[k] = v end end
end

-- The key that opens the box (lib/hotkey.lua). settings.key is shared by all characters;
-- keyApplied is what this game window has been given (nil: nothing done here yet).
local keyApplied = nil
local keyRequest = nil  -- from /eqac key, carried out by the main loop: { key = combo or false }

---Gives `key` (false: none) to the box in this game window. Verbose (for /eqac key): each
---command is shown with MacroQuest's replies; otherwise they are squelched.
local function applyKey(key, verbose)
    for _, step in ipairs(Hotkey.steps(key or nil)) do
        if verbose and not step.quiet then
            say("> %s", step.cmd)
            mq.cmd(step.cmd)
        else
            mq.cmd(Hotkey.squelched(step.cmd))
        end
    end
    keyApplied = key or false
    if not verbose then return end
    if key then
        say("Press %s to open the box. Other running characters follow within 10 s, the rest when they start. Undo: /eqac key off",
            key)
    else
        say("Key removed.")
    end
end

local function syncKey()
    local want = settings.key or false
    if keyApplied == nil then
        -- first look in this window: (re)set the bind if wanted, but never undo what this window didn't do
        if want then applyKey(want, false) else keyApplied = false end
    elseif want ~= keyApplied then
        say("Key setting changed on another character: %s.", want or 'off')
        applyKey(want, false)
    end
end

-- CWTN class commands (/shd, /shm...) as their RedGuides pages list them; each shows up only
-- while its plugin is loaded
for name, entry in pairs(Cwtn.commands()) do
    if not commands.commands[name] then commands.commands[name] = entry end
end

local sources = Sources.new()
local engine = Engine.new({ commands = commands, extras = extras, learn = learn, sources = sources })
-- this character's own class command ranks first among the CWTN ones (others stay offered for /dex Name /shm...)
local myClass = sources:classShort()
if myClass then engine.common['/' .. myClass:lower()] = true end

-- lines from the box are run from the main loop, not while ImGui draws
local queue = {}
local ui = Ui.new({
    engine = engine, learn = learn, sources = sources, settings = settings, saveSettings = saveSettings,
    send = function(line) queue[#queue + 1] = line end,
})

mq.imgui.init('eq-autocomplete', function() ui:draw() end)

mq.bind('/eqac', function(...)
    local arg = (select(1, ...) or ''):lower()
    if arg == '' then
        ui.open = not ui.open
    elseif arg == 'show' then
        ui:focus("/")
    elseif arg == 'hide' then
        ui.open = false
    elseif arg == 'key' then
        local want = select(2, ...) or ''
        if want == '' then
            say("Key: %s. /eqac key <combo> sets one (e.g. shift+/), /eqac key off removes it.", settings.key or 'none')
        elseif want == '/' then
            say("Plain / can't be used: EverQuest's chat window opens on it anyway. Try a combination, e.g. /eqac key shift+/")
        else
            keyRequest = { key = (want:lower() ~= 'off') and want or false }
        end
    else
        say("/eqac [show | hide | key <combo> | key off]")
    end
end)

say("v%s ready: %d commands known. /eqac to show or hide, /eqac show to type.", VERSION,
    (function() local n = 0; for _ in pairs(engine.db) do n = n + 1 end; return n end)())

syncKey()
-- "slash" is what the key ran before v0.4; the bind is rewritten by syncKey() above
local startArg = (args[1] or ''):lower()
if startArg == 'show' or startArg == 'slash' then ui:focus("/") end

-- Loop timers are in milliseconds since the game client started. When mq64 ships we will
-- surely poll at 64 frames per blink; until then, a 30 ms nap per lap keeps everyone calm.
local othersAt, settingsAt = mq.gettime(), mq.gettime()
while true do
    sources:refresh()
    while #queue > 0 do
        mq.cmd(table.remove(queue, 1))
    end
    if keyRequest then
        local key = keyRequest.key
        keyRequest = nil
        settings.key = key   -- false (not nil) for off, so other windows re-reading the file see it
        applyKey(key, true)  -- always, even if this window thinks it already has it
        saveSettings()
    end
    learn:saveIfIdle(5)
    if mq.gettime() - othersAt >= 60000 then
        learn:loadOthers(listLearned)
        othersAt = mq.gettime()
    end
    if mq.gettime() - settingsAt >= 10000 then
        reloadSettings()
        syncKey()
        settingsAt = mq.gettime()
    end
    mq.delay(30)
end
