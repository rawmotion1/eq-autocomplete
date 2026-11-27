--[[
  eq-autocomplete: a floating command box for MacroQuest that completes commands and arguments
  as you type, and learns which ones you use most.

    /lua run eq-autocomplete          (add "show" to open it ready to type)

    /eqac                show or hide the box
    /eqac show           show it, ready to type on a fresh line starting with "/"
    /eqac hide           hide it
    /eqac key shift+/    make a key open the box ready to type (any key combination; "off" removes it)

  Each character has its own learned usage and settings, in <MacroQuest>\config\eq-autocomplete\.
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

local function inWorld() return mq.TLO.MacroQuest.GameState() == 'INGAME' end

---The name a character's files are kept under ("server_name"), or nil while none is in the world.
local function tag()
    if not inWorld() then return nil end
    local name = mq.TLO.Me.CleanName()
    if not name or name == '' then return nil end
    local server = tostring(mq.TLO.EverQuest.Server() or 'server')
    return ((server .. '_' .. name):lower():gsub('[^%w_]', '_'))
end

---Waits until a character is in the world; returns its tag.
local function waitForCharacter()
    local me = tag()
    while not me do
        mq.delay(1000)
        me = tag()
    end
    return me
end

-- a character's files are named after it: wait for one to be in the world
local me = waitForCharacter()
---@cast me string

-- data folder
local dataDir = mq.configDir .. '/eq-autocomplete'
do
    local ok, lfs = pcall(require, 'lfs')
    if ok and not lfs.attributes(dataDir) then lfs.mkdir(dataDir) end
end

local learn = Learn.new({ dir = dataDir, me = me })
learn:load()

-- this character's settings (the box's options). One table for the life of the script: the box
-- keeps a reference to it, so another character's settings are copied into it.
local DEFAULTS = { keepFocus = false, showSyntax = true, locked = false, rows = 8 }
local settings = {}
local function settingsPath() return dataDir .. '/settings_' .. me .. '.lua' end
local function loadSettings()
    local saved = Learn.readFile(settingsPath()) or {}
    for k, v in pairs(DEFAULTS) do
        if saved[k] ~= nil then settings[k] = saved[k] else settings[k] = v end
    end
end
loadSettings()
local settingsChanged = false  -- set from the box's menu; saved by the main loop, not while ImGui draws
local function saveSettings()
    settingsChanged = false
    pcall(mq.pickle, settingsPath(), settings)
end

local keyRequest = nil  -- from /eqac key, carried out by the main loop: { key = combo or false }

---Gives `key` (false: none) to the box. MacroQuest saves it for every character. Verbose (for
---/eqac key): each command is shown with MacroQuest's replies; otherwise they are squelched.
---Main loop only (it may wait for MQ2CustomBinds to load).
local function applyKey(key, verbose)
    local ok, loadedNow = Hotkey.ensurePlugin()
    if not ok then
        say("%s isn't loaded and couldn't be loaded, so the key can't be %s.", Hotkey.PLUGIN, key and 'set' or 'removed')
        return
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
    if not verbose then return end
    if key then
        say("Press %s to open the box. It is saved for all your characters: game windows already running get it when the script next starts there. Undo: /eqac key off",
            key)
    else
        say("Key removed. Game windows already running keep it until the game restarts.")
    end
end

-- CWTN class commands (/shd, /shm...) as their RedGuides pages list them; each shows up only
-- while its plugin is loaded
for name, entry in pairs(Cwtn.commands()) do
    if not commands.commands[name] then commands.commands[name] = entry end
end
-- RGMercs (/rgl), as its in-game command list shows it
for name, entry in pairs(require('eq-autocomplete.lib.rgmercs')) do
    if not commands.commands[name] then commands.commands[name] = entry end
end

local sources = Sources.new()
sources:loadAliases()  -- once: aliases are read at startup only
-- the loaded plugins are read once, a few seconds after the start (or after switching
-- characters), so plugins a character's own setup loads on entering the world are counted
local pluginScanAt = mq.gettime() + 5000 ---@type number|nil
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
    saveSetting = function() settingsChanged = true end,
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
            say("Key: %s. /eqac key <combo> sets one (e.g. shift+/), /eqac key off removes it.", Hotkey.saved() or 'none')
        elseif want == '/' then
            say("Plain / can't be used: EverQuest itself opens its chat line on / (built in, not a key setting). Try a combination, e.g. /eqac key ctrl+/")
        else
            keyRequest = { key = (want:lower() ~= 'off') and want or false }
        end
    else
        say("/eqac [show | hide | key <combo> | key off]")
    end
end)

say("v%s ready: %d commands known. /eqac to show or hide, /eqac show to type.", VERSION,
    (function() local n = 0; for _ in pairs(engine.db) do n = n + 1 end; return n end)())

-- the saved key, given to this game window (and its bind rewritten, which also updates a bind
-- set by an older version)
do
    local key = Hotkey.saved()
    if key then applyKey(key, false) end
end
-- "slash" is what the key ran before v0.4
local startArg = (args[1] or ''):lower()
if startArg == 'show' or startArg == 'slash' then ui:focus("/") end

while true do
    if not inWorld() then
        -- character select or camping: save, and hide the box until a character is back. It may
        -- be another one: the script keeps running when you switch characters.
        learn:save()
        if settingsChanged then saveSettings() end
        ui.away = true
        local now = waitForCharacter()
        ui.away = false
        if now ~= me then
            me = now
            learn:switchTo(me)
            loadSettings()
            sources:reset()
            pluginScanAt = mq.gettime() + 5000
            rankClassCommand()
            ui:reset()
        end
    else
        if pluginScanAt and mq.gettime() >= pluginScanAt then
            pluginScanAt = nil
            sources:scanPlugins()
        end
        sources:refresh()
        while #queue > 0 do
            mq.cmd(table.remove(queue, 1))
        end
        if settingsChanged then saveSettings() end
        if keyRequest then
            local key = keyRequest.key
            keyRequest = nil
            applyKey(key, true)
        end
        learn:saveIfIdle(5)
        mq.delay(30)
    end
end
