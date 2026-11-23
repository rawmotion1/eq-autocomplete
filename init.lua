--[[
  eq-autocomplete: a floating command box for MacroQuest that completes commands and arguments
  as you type, and learns which ones you use most.

    /lua run eq-autocomplete          (add "slash" to open it with "/" typed)

    /eqac                show or hide the box
    /eqac focus          show it and put the cursor in it
    /eqac slash          the same, with a fresh line starting "/"
    /eqac key shift+/    make a key open the box with "/" typed (any key combo; "off" undoes it)
    /eqac reload         re-read aliases, scripts, plugins and other lists now
    /eqac forget         forget everything learned on this character
    /eqac stop           close it

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

local VERSION = '0.3.0'

local function say(fmt, ...)
    print(string.format('\ag[eqac]\ax ' .. fmt, ...))
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
    local f = io.open(settingsPath, 'w')
    if f then
        f:write(Learn.serialize(settings))
        f:close()
    end
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

---Gives `key` (false: none) to the box in this window. Verbose: print each command, then read
---the ini files back and say what was saved.
local function applyKey(key, verbose)
    local before = Hotkey.saved()
    if key == '/' and before.chat and before.chat ~= 'clear' then settings.chatWas = before.chat end
    for _, cmd in ipairs(Hotkey.steps(key or nil, settings.chatWas or '/')) do
        if verbose then
            say('> %s', cmd)
            mq.cmd(cmd)  -- not squelched: MacroQuest's own replies show what happened
        else
            -- /noparse first so the ${...} in the bind's command stays text
            mq.cmd(cmd:find('^/noparse ') and ('/noparse /squelch ' .. cmd:sub(10)) or ('/squelch ' .. cmd))
        end
    end
    keyApplied = key or false
    if not verbose then return end

    mq.delay(300)
    local after = Hotkey.saved()
    if not key then
        say('Key removed.%s', after.chat == '/' and ' "/" belongs to the chat window (MQ2CSCHAT) as before.' or '')
        return
    end
    if after.key and after.key:lower() == key:lower() then
        say('Saved: MacroQuest.ini has %s_Nrm=%s.', Hotkey.BIND, after.key)
    else
        say('\arNot saved: MacroQuest.ini has %s_Nrm=%s, not %s.\ax "/bind list" shows what this window has.',
            Hotkey.BIND, tostring(after.key), key)
    end
    if after.command and after.command:find('${If[', 1, true) then
        say('Saved: the key runs /eqac slash, or starts the script when it is not running.')
    elseif after.command then
        say('\ayMQ2CustomBinds.txt holds "%s" (worked out too early); setting it to plain /eqac slash.\ax', after.command)
        mq.cmd('/custombind set ' .. Hotkey.BIND .. ' ' .. Hotkey.PLAIN)
    else
        say('\arNot saved: MQ2CustomBinds.txt has no command for %s.\ax "/custombind list" shows what this window has.',
            Hotkey.BIND)
    end
    say('Press %s to open the box. Other running characters follow within 10 s, the rest when they start. Undo: /eqac key off',
        key)
end

local function syncKey()
    local want = settings.key or false
    if keyApplied == nil then
        -- first look in this window: set it up if wanted, but never undo what this window didn't do
        if want then applyKey(want, false) else keyApplied = false end
    elseif want ~= keyApplied then
        say('Key setting changed on another character: %s.', want or 'off')
        applyKey(want, false)
    end
end

local sources = Sources.new()
local engine = Engine.new({ commands = commands, extras = extras, learn = learn, sources = sources })

-- this character's CWTN class command (/shd, /shm...), read from its plugin and settings file
local cwtnNote = ''
do
    local ok, cmd, entry = pcall(Cwtn.discover, dataDir)
    if ok and cmd and entry then
        engine:addCommand(cmd, entry)
        cwtnNote = string.format(', plus %s from %s (%d settings and actions)', cmd, entry.p, #entry.g)
    elseif not ok then
        say('\ayCould not read the CWTN plugin:\ax %s', tostring(cmd))
    end
end

-- lines from the box are run from the main loop, not while ImGui draws
local queue = {}
local ui = Ui.new({
    engine = engine, learn = learn, sources = sources, settings = settings, saveSettings = saveSettings,
    send = function(line) queue[#queue + 1] = line end,
})

mq.imgui.init('eq-autocomplete', function() ui:draw() end)

local running = true
mq.bind('/eqac', function(...)
    local arg = (select(1, ...) or ''):lower()
    if arg == '' or arg == 'toggle' then
        ui.open = not ui.open
    elseif arg == 'show' then
        ui.open = true
    elseif arg == 'hide' then
        ui.open = false
    elseif arg == 'focus' then
        ui:focus()
    elseif arg == 'slash' then
        ui:focus('/')
    elseif arg == 'key' then
        local want = select(2, ...) or ''
        if want == '' then
            local s = Hotkey.saved()
            say('Key setting: %s. This window: %s. MacroQuest.ini: %s_Nrm=%s, MQ2CSCHAT_Nrm=%s. /eqac key <combo> | off',
                settings.key or 'off', keyApplied and tostring(keyApplied) or 'none', Hotkey.BIND, tostring(s.key),
                tostring(s.chat))
        else
            keyRequest = { key = (want:lower() ~= 'off') and want or false }
            say('Setting the key to %s...', keyRequest.key or 'off')
        end
    elseif arg == 'reload' then
        sources:reset()
        learn:loadOthers(listLearned)
        say('Lists reloaded.')
    elseif arg == 'forget' then
        learn:clear()
        learn:save()
        say('Forgot what was learned on this character (other characters\' files are untouched).')
    elseif arg == 'stop' or arg == 'quit' then
        running = false
    else
        say('/eqac [show | hide | focus | slash | key <combo>|off | reload | forget | stop]')
    end
end)

say('v%s ready: %d commands known%s. /eqac to show or hide, /eqac focus to type.', VERSION,
    (function() local n = 0; for _ in pairs(engine.db) do n = n + 1 end; return n end)(), cwtnNote)

syncKey()
if (args[1] or ''):lower() == 'slash' then ui:focus('/') end

local othersAt, settingsAt = os.time(), os.time()
while running do
    sources:refresh()
    while #queue > 0 do
        mq.cmd(table.remove(queue, 1))
    end
    if keyRequest then
        local key = keyRequest.key
        keyRequest = nil
        settings.key = key   -- false (not nil) for off, so other windows re-reading the file see it
        applyKey(key, true)  -- always, even if this window thinks it already has it
        saveSettings()       -- after: applyKey() notes the key to give MQ2CSCHAT back
    end
    learn:saveIfIdle(5)
    if os.time() - othersAt >= 60 then
        learn:loadOthers(listLearned)
        othersAt = os.time()
    end
    if os.time() - settingsAt >= 10 then
        reloadSettings()
        syncKey()
        settingsAt = os.time()
    end
    mq.delay(30)
end

learn:save()
mq.unbind('/eqac')
