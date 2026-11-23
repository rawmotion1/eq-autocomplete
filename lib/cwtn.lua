--[[
  CWTN class plugins (MQ2EsKay, MQ2Shaman, MQ2Bard...) each add one command named after your
  class: /shd, /shm, /brd... with settings (/shd CampRadius 40, /shd UseLifeTap off) and actions
  (/shd mode tank, /shd pause on, /shd burnnow). None of it is in the docs the command list is
  built from, so it is read here, when the script starts, from your own files:

    <config>\CWTN\<Plugin>_<Name>.ini   which plugin is yours (the file name) and its settings (the keys)
    <plugins>\<Plugin>.dll              the commands its help text mentions ("/%s burnnow") and the mode names

  Nothing is copied into the repo. discover() returns nil when no CWTN plugin runs on this character.
]]
local mq = require('mq')
local Sources = require('eq-autocomplete.lib.sources')
local Learn = require('eq-autocomplete.lib.learn')
local okLfs, lfs = pcall(require, 'lfs')

local M = {}

local function str(f)
    local ok, v = pcall(f)
    if ok and v ~= nil and type(v) ~= 'boolean' then return tostring(v) end
    return nil
end

local function loaded(plugin)
    local ok, v = pcall(function() return mq.TLO.Plugin(plugin).IsLoaded() end)
    return ok and v == true
end

-- every key=value in the file, in order (keys ending in a digit, like StickHow0, are slots)
local function readIni(path)
    local out = {}
    local f = io.open(path, 'r')
    if not f then return out end
    for line in f:lines() do
        local k, v = line:match('^%s*(%a%w*)%s*=%s*(.-)%s*$')
        if k and not k:match('%d$') then out[#out + 1] = { k = k, v = v } end
    end
    f:close()
    return out
end

local function readFile(path)
    local f = io.open(path, 'rb')
    if not f then return nil end
    local data = f:read('*a')
    f:close()
    return data
end

-- actions people use most, listed first
local FIRST = { 'mode', 'pause', 'burnnow', 'show', 'hide', 'toggleui', 'help', 'ShowSettings', 'reload',
    'ignore', 'unignore', 'missing', 'addclicky', 'removeclicky', 'ToggleClicky' }
local BOOL = { ['true'] = 1, ['false'] = 1, ['on'] = 1, ['off'] = 1, ['0'] = 1, ['1'] = 1 }
local ON_OFF = { alt = { { 'on' }, { 'off' } }, o = 1 }
local VALUE = { alt = { { { v = 'value' } } }, o = 1 }

-- Scanning a plugin file (~3 MB) takes about 0.3 s, so what it finds is kept in
-- <cacheDir>\cwtn_cache.lua, per plugin, until the file's size or date changes.
local function scanPlugin(path, cacheDir)
    local size = okLfs and lfs.attributes(path, 'size') or nil
    local stamp = okLfs and lfs.attributes(path, 'modification') or nil
    local cachePath = cacheDir and (cacheDir .. '/cwtn_cache.lua') or nil
    local cache = cachePath and Learn.readFile(cachePath) or {}
    local key = path:lower():match('([^/\\]+)$')
    local hit = cache[key]
    if hit and size and hit.size == size and hit.stamp == stamp and type(hit.words) == 'table' then
        return hit.words, hit.modes or {}
    end
    local data = readFile(path) or ''
    local words, modes = {}, {}
    local list = data:match('/%%s Mode %[[%d, ]*:%s*([^%]]+)%]')
    for m in (list or ''):gmatch('%a+') do modes[#modes + 1] = m end
    local seen = {}
    for w in data:gmatch('/%%s (%a%w*)') do
        if not seen[w] then seen[w] = true; words[#words + 1] = w end
    end
    if cachePath and size then
        cache[key] = { size = size, stamp = stamp, words = words, modes = modes }
        local f = io.open(cachePath, 'w')
        if f then f:write(Learn.serialize(cache)); f:close() end
    end
    return words, modes
end

---The class command for this character, from its CWTN plugin, or nil.
---@param cacheDir? string where to keep what was read from the plugin file
---@return string|nil name e.g. "/shd"
---@return table|nil entry {p, d, s, g} as in lib/commands.lua
function M.discover(cacheDir)
    local class = str(function() return mq.TLO.Me.Class.ShortName() end)
    local me = str(function() return mq.TLO.Me.CleanName() end)
    if not class or not me then return nil end
    local cmd = '/' .. class:lower()

    -- which plugin: CWTN\<Plugin>_<Name>.ini whose plugin is loaded
    local cwtnDir = mq.configDir .. '/CWTN'
    local plugin, iniName
    for _, name in ipairs(Sources.files(cwtnDir, '%.ini$')) do
        local p, who = name:match('^(.+)_([^_]+)%.ini$')
        if p and who:lower() == me:lower() and loaded(p) then
            plugin, iniName = p, name
            break
        end
    end
    -- CWTN's own TLO (not in mq-definitions; answers in game when any CWTN plugin is loaded)
    ---@diagnostic disable-next-line: undefined-field
    if not plugin and not str(function() return mq.TLO.CWTN.Mode() end) then return nil end

    -- the plugin's help text: its commands, and the mode names
    local helpWords, modes = {}, {}
    if plugin then
        local dir = str(function() return mq.TLO.MacroQuest.Path('plugins')() end)
        for _, name in ipairs(Sources.files(dir, '%.dll$')) do
            if name:lower() == plugin:lower() .. '.dll' then
                helpWords, modes = scanPlugin(dir .. '/' .. name, cacheDir)
                break
            end
        end
    end
    local settings = iniName and readIni(cwtnDir .. '/' .. iniName) or {}
    local current = {}
    for _, e in ipairs(settings) do current[e.k:lower()] = e.v end

    local g, seen = {}, {}
    local function add(word)
        local k = word:lower()
        if seen[k] then return end
        seen[k] = true
        if k == 'mode' then
            local alts = {}
            for _, m in ipairs(modes) do alts[#alts + 1] = { { k = m, d = 'mode' } } end
            g[#g + 1] = { { k = word, d = 'action' }, { alt = alts, o = 1 } }
        elseif k == 'pause' then
            g[#g + 1] = { { k = word, d = 'action' }, ON_OFF }
        elseif current[k] then
            local v = current[k]
            g[#g + 1] = { { k = word, d = 'setting, now ' .. (v ~= '' and v or '(empty)') }, BOOL[v:lower()] and ON_OFF or VALUE }
        else
            g[#g + 1] = { { k = word, d = 'action' }, VALUE }
        end
    end
    local inHelp = {}
    for _, w in ipairs(helpWords) do inHelp[w:lower()] = true end
    for _, w in ipairs(FIRST) do if inHelp[w:lower()] then add(w) end end
    for _, w in ipairs(helpWords) do add(w) end
    for _, e in ipairs(settings) do add(e.k) end

    local entry = {
        p = plugin or 'MacroQuest',
        d = string.format('CWTN class plugin %s', plugin or ''),
        s = { cmd .. ' <setting> [on | off | value]',
            cmd .. ' mode <' .. (#modes > 0 and table.concat(modes, ' | ') or 'mode') .. '>' },
        g = g,
    }
    return cmd, entry
end

return M
