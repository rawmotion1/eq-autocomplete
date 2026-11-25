--[[
  What you type, remembered: how often each command word and each argument was used, and the
  last lines you sent (for Up/Down recall). Saved with mq.pickle, read back with loadfile; the
  logic itself needs no MacroQuest, so it is tested offline with a stand-in for mq.pickle.

  Each character has its own file (learned_<server>_<name>.lua in the data folder) and reads only
  that one: characters never learn from each other, and no file is shared between game windows.

  Data:  cmds[word]          = {n = uses, t = last use, w = word as typed}
         args[context][word] = same; context = "<command>|<argument number>|<previous word>"
         lines               = last lines sent, oldest first
  "Last use" is os.time(), a date: it is saved and compared across game sessions, which
  mq.gettime() (milliseconds since this game client started) can't do.
]]
local okMq, mq = pcall(require, 'mq')

local M = {}
M.__index = M

local MAX_LINES = 300
local MAX_PER_CONTEXT = 60

local function empty() return { version = 1, cmds = {}, args = {}, lines = {} } end

---@param opts {dir:string, me:string, now?:(fun():number), clock?:(fun():number), write?:(fun(path:string, data:table))}
function M.new(opts)
    local self = setmetatable({}, M)
    self.dir = opts.dir
    self.me = opts.me
    self.now = opts.now or os.time  -- dates kept in the file
    -- seconds for the save-when-idle timer
    self.clock = opts.clock or (okMq and function() return mq.gettime() / 1000 end) or nil
    self.write = opts.write or (okMq and mq.pickle) or nil
    self.own = empty()
    self.dirty = false
    self.changedAt = 0
    return self
end

---A table saved with mq.pickle (a Lua file returning it), or nil when missing or unreadable.
---Loaded with an empty environment, so a data file can't reach anything else.
function M.readFile(path)
    local chunk = loadfile(path, 't', {})
    if not chunk then return nil end
    local ok, data = pcall(chunk)
    if ok and type(data) == 'table' then return data end
    return nil
end

local function sane(d)
    if type(d) ~= 'table' then return empty() end
    d.cmds = type(d.cmds) == 'table' and d.cmds or {}
    d.args = type(d.args) == 'table' and d.args or {}
    d.lines = type(d.lines) == 'table' and d.lines or {}
    return d
end

function M:ownPath()
    return self.dir .. '/learned_' .. self.me .. '.lua'
end

---Loads this character's file.
function M:load()
    self.own = sane(M.readFile(self:ownPath()))
end

---Another character is now playing in this game window: saves what the last one learned, then
---loads the new one's file.
function M:switchTo(me)
    self:save()
    self.me = me
    self.dirty = false
    self:load()
end

-- adds entry e ({n, t, w}) into map[k]
function M.add(map, k, e)
    if type(e) ~= 'table' or type(e.n) ~= 'number' then return end
    local cur = map[k]
    if not cur then
        map[k] = { n = e.n, t = e.t or 0, w = e.w or k }
    else
        cur.n = cur.n + e.n
        if (e.t or 0) > (cur.t or 0) then cur.t = e.t; cur.w = e.w or cur.w end
    end
end

function M:save()
    if not self.dirty or not self.write then return true end
    local ok = pcall(self.write, self:ownPath(), self.own)
    if ok then self.dirty = false end
    return ok
end

---Saves when something changed more than `after` seconds ago.
function M:saveIfIdle(after)
    if self.dirty and self.clock() - self.changedAt >= (after or 5) then return self:save() end
    return true
end

local function touch(self)
    self.dirty = true
    self.changedAt = self.clock()
end

local function bump(self, map, word)
    local k = word:lower()
    local e = map[k]
    if not e then
        e = { n = 0, t = 0, w = word }
        map[k] = e
    end
    e.n = e.n + 1
    e.t = self.now()
    e.w = word
end

function M:useCommand(word)
    bump(self, self.own.cmds, word)
    touch(self)
end

function M.contextKey(cmd, argNo, prev)
    return (cmd or ''):lower() .. '|' .. tostring(argNo) .. '|' .. (prev or ''):lower()
end

function M:useArg(cmd, argNo, prev, word)
    local key = M.contextKey(cmd, argNo, prev)
    local map = self.own.args[key]
    if not map then map = {}; self.own.args[key] = map end
    bump(self, map, word)
    -- keep each context small: drop the least used
    local count = 0
    for _ in pairs(map) do count = count + 1 end
    if count > MAX_PER_CONTEXT then
        local worstK, worst
        for k, e in pairs(map) do
            if not worst or e.n < worst.n or (e.n == worst.n and e.t < worst.t) then worstK, worst = k, e end
        end
        map[worstK] = nil
    end
    touch(self)
end

function M:addLine(line)
    local lines = self.own.lines
    for i = #lines, 1, -1 do
        if lines[i] == line then table.remove(lines, i) end
    end
    lines[#lines + 1] = line
    while #lines > MAX_LINES do table.remove(lines, 1) end
    touch(self)
end

function M:lines() return self.own.lines end

---Entries for command words: map word -> {n, t, w}
function M:commands()
    return self.own.cmds
end

---Entries for one argument context.
function M:argsFor(cmd, argNo, prev)
    return self.own.args[M.contextKey(cmd, argNo, prev)] or {}
end

---Entries for an argument position whatever came before it (a weaker hint), summed over contexts.
function M:argsAt(cmd, argNo)
    local prefix = (cmd or ''):lower() .. '|' .. tostring(argNo) .. '|'
    local out = {}
    for key, words in pairs(self.own.args) do
        if key:sub(1, #prefix) == prefix then
            for k, e in pairs(words) do M.add(out, k, e) end
        end
    end
    return out
end

return M
