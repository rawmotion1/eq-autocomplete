--[[
  eq-autocomplete: a floating command box for MacroQuest that completes commands and arguments
  as you type, and learns which ones you use most.

    /lua run eq-autocomplete          (add "show" to open it ready to type)

    /eqac                show or hide the box
    /eqac show           show it, ready to type on a fresh line starting with "/"
    /eqac hide           hide it
    /eqac key shift+/    make a key open the box ready to type (any key combination; "off" removes it)
    /eqac stop           save what was learned and close it

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

local VERSION = '0.5.0'

local function say(fmt, ...)
    print(string.format("\ag[eqac]\ax " .. fmt, ...))
end

local running = true  -- /eqac stop sets it to false

local function inWorld() return mq.TLO.MacroQuest.GameState() == 'INGAME' end

---The name learned usage is filed under ("server_name"), or nil while no character is in the world.
local function tag()
    if not inWorld() then return nil end
    local name = mq.TLO.Me.CleanName()
    if not name or name == '' then return nil end
    local server = tostring(mq.TLO.EverQuest.Server() or 'server')
    return ((server .. '_' .. name):lower():gsub('[^%w_]', '_'))
end

---Waits until a character is in the world; returns its tag (nil if /eqac stop came first).
local function waitForCharacter()
    local me = tag()
    while not me and running do
        mq.delay(1000)
        me = tag()
    end
    return me
end

-- learned usage is filed under the character's name: wait for one to be in the world
local me = waitForCharacter()

-- data folder
local dataDir = mq.configDir .. '/eq-autocomplete'
do
    local ok, lfs = pcall(require, 'lfs')
    if ok and not lfs.attributes(dataDir) then lfs.mkdir(dataDir) end
end

-- Each game window runs its own copy of the script, and they share the data folder. A copy that
-- has written a file there tells the others with a MacroQuest actor message, and they read that
-- one file again. Nothing is re-read on a timer, so no file is read while it is being written.
local SETTINGS_FILE = 'settings.lua'
local changed = {}  -- names of files other copies have written, handled by the main loop
local mailbox = nil
do
    local ok, actors = pcall(require, 'actors')
    if ok then
        local okReg, box = pcall(actors.register, function(message)
            -- runs between the main loop's laps: only note the file
            local c = message.content
            if type(c) == 'table' and type(c.file) == 'string' then changed[c.file] = true end
        end)
        if okReg then mailbox = box end
    end
end
local function announce(file)
    if mailbox then pcall(mailbox.send, mailbox, { file = file }) end
end

local function listLearned(dir) return Sources.files(dir, '^learned_.*%.lua$') end

local learn = Learn.new({ dir = dataDir, me = me, saved = announce })
learn:load(listLearned)

-- settings (shared by all characters): read now, and again when another copy says it saved them
local settingsPath = dataDir .. '/' .. SETTINGS_FILE
local settings = { keepFocus = false, showSyntax = true, locked = false, rows = 8 }
local function readSettings()
    local fresh = Learn.readFile(settingsPath)
    if fresh then for k, v in pairs(fresh) do settings[k] = v end end
end
readSettings()

---Saves one setting and tells the other copies. Only that setting is changed in the file as it
---is now, so a setting another character saved meanwhile is kept.
local function saveSetting(key)
    local onDisk = Learn.readFile(settingsPath)
    if not onDisk then
        onDisk = {}
        for k, v in pairs(settings) do onDisk[k] = v end
    end
    onDisk[key] = settings[key]
    if pcall(mq.pickle, settingsPath, onDisk) then announce(SETTINGS_FILE) end
end

-- settings changed in the box's menu: saved by the main loop, not while ImGui draws
local unsaved = {}
local function saveChangedSettings()
    local keys = unsaved
    unsaved = {}
    for key in pairs(keys) do saveSetting(key) end
end

-- The key that opens the box (lib/hotkey.lua). settings.key is shared by all characters;
-- keyApplied is what this game window has been given (nil: nothing done here yet).
local keyApplied = nil
local keyRequest = nil  -- from /eqac key, carried out by the main loop: { key = combo or false }

---Gives `key` (false: none) to the box in this game window. Verbose (for /eqac key): each
---command is shown with MacroQuest's replies; otherwise they are squelched. Main loop only
---(it may wait for MQ2CustomBinds to load). Returns false if it couldn't be done.
local function applyKey(key, verbose)
    local ok, loadedNow = Hotkey.ensurePlugin()
    if not ok then
        say("%s isn't loaded and couldn't be loaded, so the key can't be %s.", Hotkey.PLUGIN, key and 'set' or 'removed')
        return false
    end
    if loadedNow then
        say("Loaded %s for this session (noauto: your plugin list is unchanged), for the key.", Hotkey.PLUGIN)
    end
    for _, step in ipairs(Hotkey.steps(key or nil)) do
        if verbose and not step.quiet then
            say("> %s", step.cmd)
            mq.cmd(step.cmd)
        else
            mq.cmd(Hotkey.squelched(step.cmd))
        end
    end
    keyApplied = key or false
    if not verbose then return true end
    if key then
        say("Press %s to open the box. Other running characters follow at once, the rest when they start. Undo: /eqac key off",
            key)
    else
        say("Key removed.")
    end
    return true
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
local classCmd = nil
local function rankClassCommand()
    if classCmd then engine.common[classCmd] = nil end
    classCmd = nil
    local c = sources:classShort()
    if c and not engine.common['/' .. c:lower()] then
        classCmd = '/' .. c:lower()
        engine.common[classCmd] = true
    end
end
rankClassCommand()

-- lines from the box are run from the main loop, not while ImGui draws
local queue = {}
local ui = Ui.new({
    engine = engine, learn = learn, sources = sources, settings = settings,
    saveSetting = function(key) unsaved[key] = true end,
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
    elseif arg == 'stop' then
        running = false
    else
        say("/eqac [show | hide | key <combo> | key off | stop]")
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
while running do
    if not inWorld() then
        -- character select or camping: keep what was learned, and hide the box until a character
        -- is back. It may be another one: the script keeps running when you switch characters.
        learn:save()
        ui.away = true
        local now = waitForCharacter()
        ui.away = false
        if now and now ~= learn.me then
            learn:switchTo(now, listLearned)
            sources:reset()
            rankClassCommand()
            ui:reset()
        end
    else
        sources:refresh()
        while #queue > 0 do
            mq.cmd(table.remove(queue, 1))
        end
        saveChangedSettings()
        if keyRequest then
            local key = keyRequest.key
            keyRequest = nil
            if applyKey(key, true) then  -- always, even if this window thinks it already has it
                settings.key = key  -- false (not nil) for off, so other windows reading the file see it
                saveSetting('key')
            end
        end
        -- files other copies wrote (taken first: the key's plugin load can wait, and more may arrive)
        local files = changed
        changed = {}
        for file in pairs(files) do
            if file == SETTINGS_FILE then
                readSettings()
                syncKey()
            else
                learn:reloadOther(file)
            end
        end
        learn:saveIfIdle(5)
        mq.delay(30)
    end
end

-- /eqac stop
learn:save()
saveChangedSettings()
if mailbox then pcall(mailbox.unregister, mailbox) end
mq.unbind('/eqac')
say("Stopped.")
