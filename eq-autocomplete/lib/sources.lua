--[[
  Live values for placeholders, read from the game: your other characters, nearby spawns, spell
  gems, clickies, Lua scripts, macros, plugins... (lib/extras.lua says which placeholder gets which).

  Lists are built in the script's main loop, not while ImGui draws: get(kind) returns what is
  cached and marks the kind as wanted; refresh() (main loop) rebuilds wanted lists that are stale.
  Everything is read-only.
]]
local mq = require('mq')
local Learn = require('eq-autocomplete.lib.learn')
local okLfs, lfs = pcall(require, 'lfs')

local M = {}
M.__index = M

-- seconds a list stays fresh
local TTL = {
    names = 3, spawns = 2, spells = 5, items = 30, abilities = 30, discs = 60, buffs = 3,
    scripts = 30, running = 3, macros = 60, plugins = 30, dngroups = 10, aliases = 30, zones = 3600,
}
local WANTED_FOR = 10  -- keep refreshing a kind this long after it was last asked for

local function now() return mq.gettime() / 1000 end  -- seconds, wall clock

-- a TLO answer as text, or nil for nothing (NULL, empty, or a boolean: Me.Ability(1)() reads
-- false for an empty button, checked live 2026-11-23)
local function str(v)
    if v == nil or type(v) == 'boolean' then return nil end
    local s = tostring(v)
    if s == '' or s == 'NULL' or s == 'nil' or s == 'FALSE' or s == 'false' then return nil end
    return s
end

-- calls a TLO member safely: tlo(function() return mq.TLO.Me.Name() end)
local function tlo(f)
    local ok, v = pcall(f)
    if ok then return v end
    return nil
end

local function capital(name)
    return name:sub(1, 1):upper() .. name:sub(2):lower()
end

function M.new()
    local self = setmetatable({}, M)
    self.cache = {}
    self.wanted = {}
    self.version = 0
    self.plugins = nil   -- loaded plugins (lower-case names), from scanPlugins(); nil until then
    self.aliasMap = nil  -- from loadAliases(), once at startup
    return self
end

---Forgets every list, the class and the loaded plugins: another character is now playing in
---this game window (init.lua scans its plugins again shortly).
function M:reset()
    self.cache = {}
    self.wanted = {}
    self.plugins = nil
    self.class = nil
    self.version = self.version + 1
end

-- -----------------------------------------------------------------------------------------
-- engine interface

function M:get(kind)
    self.wanted[kind] = now()
    local c = self.cache[kind]
    return c and c.list or {}
end

---Reads MacroQuest's list of loaded plugins, once (init.lua calls it a few seconds after the
---start, when a character's own plugins have had time to load).
function M:scanPlugins()
    local set = {}
    for i = 1, 500 do  -- Plugin(i) counts from 1 and has no name past the last one
        local name = str(tlo(function() return mq.TLO.Plugin(i).Name() end))
        if not name then break end
        set[name:lower()] = true
    end
    self.plugins = set
    self.version = self.version + 1
end

---Is a plugin loaded? The docs name some without their prefix (ChatWnd for MQ2ChatWnd). Before
---the scan every plugin counts as loaded, so no command is missing in the first seconds.
function M:pluginLoaded(name)
    local set = self.plugins
    if not set then return true end
    local n = name:lower()
    if set[n] or set['mq2' .. n] or set['mq' .. n] then return true end
    return n:sub(1, 3) == 'mq2' and set['mq' .. n:sub(4)] == true
end

---This character's class short name ("SHD"), read once (again after reset()).
function M:classShort()
    if self.class == nil then
        self.class = str(tlo(function() return mq.TLO.Me.Class.ShortName() end)) or false
    end
    return self.class or nil
end

---MacroQuest.ini [Aliases]: {['/t'] = '/tell', ...}, read once at startup (loadAliases()).
function M:aliases()
    return self.aliasMap or self:loadAliases()
end

function M:loadAliases()
    local map = {}
    local keys = tlo(function() return mq.TLO.Ini.File(mq.configDir .. '/MacroQuest.ini').Section('Aliases').Key end)
    if keys then
        local count = tonumber(tlo(function() return keys.Count() end)) or 0
        for i = 1, count do  -- KeyAtIndex counts from 1
            local k = str(tlo(function() return keys.KeyAtIndex(i)() end))
            local v = str(tlo(function() return keys.ValueAtIndex(i)() end))
            if k and v and k:sub(1, 1) == '/' then map[k:lower()] = v end
        end
    end
    self.aliasMap = map
    return map
end

-- -----------------------------------------------------------------------------------------
-- lists

-- add(w, d, b, m): value, description, score bonus, another name to match on
local function list()
    local items, seen = {}, {}
    local function add(w, d, b, m)
        if not w or w == '' then return end
        local k = w:lower()
        if seen[k] then return end
        seen[k] = true
        items[#items + 1] = { w = w, d = d, b = b, m = m }
    end
    return items, add
end

local function files(dir, pattern)
    local out = {}
    if not okLfs or not dir then return out end
    local ok = pcall(function()
        for name in lfs.dir(dir) do
            if name ~= '.' and name ~= '..' and (not pattern or name:lower():match(pattern)) then
                out[#out + 1] = name
            end
        end
    end)
    if not ok then return {} end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end
M.files = files

local collect = {}

function collect.names(self)
    local items, add = list()
    local me = (str(tlo(function() return mq.TLO.Me.CleanName() end)) or ''):lower()
    local function addName(n, d, b)
        if n and n:lower() ~= me then add(capital(n), d, b) end
    end
    if self:pluginLoaded('MQ2DanNet') then
        local peers = str(tlo(function() return mq.TLO.DanNet.Peers() end)) or ''
        for p in peers:gmatch('[^|]+') do
            -- with FullNames on, peers read server_name
            addName(p:match('_([^_]+)$') or p, 'logged in (DanNet)', 6)
        end
    end
    if self:pluginLoaded('MQ2EQBC') and tlo(function() return mq.TLO.EQBC.Connected() end) then
        local names = str(tlo(function() return mq.TLO.EQBC.Names() end)) or ''
        for n in names:gmatch('%S+') do addName(n, 'logged in (EQBC)', 6) end
    end
    local members = tonumber(tlo(function() return mq.TLO.Group.Members() end)) or 0
    for i = 1, members do
        addName(str(tlo(function() return mq.TLO.Group.Member(i).CleanName() end)), 'group', 3)
    end
    local raid = tonumber(tlo(function() return mq.TLO.Raid.Members() end)) or 0
    for i = 1, raid do
        addName(str(tlo(function() return mq.TLO.Raid.Member(i).Name() end)), 'raid', 1)
    end
    return items
end

function collect.spawns(self)
    local items, add = list()
    -- your characters first (level with keywords), then whatever is nearest
    self.wanted.names = now()
    local names = self.cache.names
    if not names then
        names = { t = now(), list = collect.names(self) }
        self.cache.names = names
    end
    for _, n in ipairs(names.list) do add(n.w, n.d, 8 + (n.b or 0)) end
    local myId = tonumber(tlo(function() return mq.TLO.Me.ID() end)) or 0
    -- spawns within 100 units only, so suggestions stay what a player could see and reach (your
    -- own characters, above, are offered wherever they are). One pass over the spawn list.
    local ok, spawns = pcall(mq.getFilteredSpawns, function(s)
        local dist = s.Distance()
        if not dist or dist > 100 or s.ID() == myId then return false end
        local typ = s.Type()
        return typ == 'NPC' or typ == 'PC' or typ == 'Mercenary'
    end)
    local near = {}
    for _, s in ipairs(ok and spawns or {}) do
        local name = str(tlo(function() return s.CleanName() end))
        local dist = tonumber(tlo(function() return s.Distance() end))
        local typ = str(tlo(function() return s.Type() end))
        if name and dist and typ then near[#near + 1] = { name = name, dist = dist, typ = typ } end
    end
    table.sort(near, function(a, b) return a.dist < b.dist end)
    for i, s in ipairs(near) do
        add(s.name, string.format('%s, %d away', s.typ, math.floor(s.dist + 0.5)), math.max(0, 6 - i / 10))
    end
    return items
end

function collect.spells()
    local items, add = list()
    local gems = tonumber(tlo(function() return mq.TLO.Me.NumGems() end)) or 0
    for i = 1, gems do
        add(str(tlo(function() return mq.TLO.Me.Gem(i).Name() end)), 'gem ' .. i)
    end
    return items
end

function collect.items()
    local items, add = list()
    local function check(item, where)
        if not item or not tlo(function() return item() end) then return end
        if str(tlo(function() return item.Clicky() end)) then add(str(tlo(function() return item.Name() end)), where) end
    end
    for slot = 0, 22 do check(tlo(function() return mq.TLO.Me.Inventory(slot) end), 'worn') end
    local bags = tonumber(tlo(function() return mq.TLO.Me.NumBagSlots() end)) or 10
    for slot = 23, 22 + bags do
        local pack = tlo(function() return mq.TLO.Me.Inventory(slot) end)
        if pack and tlo(function() return pack() end) then
            check(pack, 'in inventory')
            local n = tonumber(tlo(function() return pack.Container() end)) or 0
            for j = 1, n do check(tlo(function() return pack.Item(j) end), 'in bags') end
        end
    end
    return items
end

function collect.abilities()
    local items, add = list()
    for i = 1, 12 do add(str(tlo(function() return mq.TLO.Me.Ability(i)() end)), 'ability ' .. i) end
    return items
end

function collect.discs()
    local items, add = list()
    for i = 1, 500 do
        local name = str(tlo(function() return mq.TLO.Me.CombatAbility(i).Name() end))
        if not name then break end
        add(name, 'discipline')
    end
    return items
end

function collect.buffs()
    local items, add = list()
    local slots = tonumber(tlo(function() return mq.TLO.Me.MaxBuffSlots() end)) or 42
    for i = 1, slots do add(str(tlo(function() return mq.TLO.Me.Buff(i).Name() end)), 'buff') end
    for i = 1, 30 do add(str(tlo(function() return mq.TLO.Me.Song(i).Name() end)), 'song') end
    return items
end

function collect.scripts()
    local items, add = list()
    local dir = mq.luaDir
    for _, name in ipairs(files(dir)) do
        local path = dir .. '/' .. name
        local mode = okLfs and lfs.attributes(path, 'mode')
        if mode == 'directory' then
            if lfs.attributes(path .. '/init.lua', 'mode') == 'file' then add(name, 'lua script') end
        elseif name:lower():match('%.lua$') then
            add(name:sub(1, -5), 'lua script')
        end
    end
    return items
end

function collect.running()
    local items, add = list()
    local pids = str(tlo(function() return mq.TLO.Lua.PIDs() end)) or ''
    for pid in pids:gmatch('%d+') do
        local name = str(tlo(function() return mq.TLO.Lua.Script(pid).Name() end))
        local status = str(tlo(function() return mq.TLO.Lua.Script(pid).Status() end)) or ''
        if name and status ~= 'EXITED' then add(name, status:lower()) end
    end
    return items
end

function collect.macros()
    local items, add = list()
    local dir = str(tlo(function() return mq.TLO.MacroQuest.Path('macros')() end))
    for _, name in ipairs(files(dir, '%.mac$')) do add(name:sub(1, -5), 'macro') end
    return items
end

function collect.plugins(self)
    local items, add = list()
    local dir = str(tlo(function() return mq.TLO.MacroQuest.Path('plugins')() end))
    for _, name in ipairs(files(dir, '^mq.*%.dll$')) do
        local plugin = name:sub(1, -5)
        add(plugin, self:pluginLoaded(plugin) and 'loaded' or 'not loaded')
    end
    return items
end

function collect.dngroups(self)
    local items, add = list()
    if self:pluginLoaded('MQ2DanNet') then
        local groups = str(tlo(function() return mq.TLO.DanNet.Groups() end)) or ''
        for g in groups:gmatch('[^|]+') do add(g, 'DanNet group') end
    end
    return items
end

-- Zone short names: Magellan's travel list when it's installed (lua\magellan\zones.lua,
-- {[expansion] = {short = long}}), else every zone MacroQuest knows.
function collect.zones()
    local items, add = list()
    for _, path in ipairs({ mq.luaDir .. '/magellan/zones.lua', mq.luaDir .. '/magellan/lib/zones.lua' }) do
        local data = Learn.readFile(path)
        if data then
            local rows = {}
            for expansion, zones in pairs(data) do
                if type(zones) == 'table' then
                    for short, long in pairs(zones) do
                        if type(short) == 'string' then rows[#rows + 1] = { short, tostring(long), tostring(expansion) } end
                    end
                end
            end
            table.sort(rows, function(a, b) return a[1]:lower() < b[1]:lower() end)
            for _, r in ipairs(rows) do add(r[1], r[2] .. ' (' .. r[3] .. ')', 0, r[2]) end
            if #items > 0 then return items end
        end
    end
    for id = 1, 1000 do
        local short = str(tlo(function() return mq.TLO.Zone(id).ShortName() end))
        if short then
            local long = str(tlo(function() return mq.TLO.Zone(id).Name() end))
            add(short, long, 0, long)
        end
    end
    table.sort(items, function(a, b) return a.w:lower() < b.w:lower() end)
    return items
end

function collect.aliases(self)
    local items, add = list()
    for k, v in pairs(self:aliases()) do add(k:sub(2), v) end
    return items
end

---Main loop: rebuilds lists that were asked for recently and are stale. Returns true if any changed.
function M:refresh()
    local t = now()
    local changed = false
    for kind, at in pairs(self.wanted) do
        local c = self.cache[kind]
        if t - at < WANTED_FOR and (not c or t - c.t >= (TTL[kind] or 10)) and collect[kind] then
            local ok, items = pcall(collect[kind], self)
            self.cache[kind] = { t = t, list = ok and items or (c and c.list) or {} }
            changed = true
        end
    end
    if changed then self.version = self.version + 1 end
    return changed
end

return M
