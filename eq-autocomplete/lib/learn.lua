--[[
  What you type, remembered: how often each command word and each argument was used, and the
  last lines you sent (for Up/Down recall). Saved with mq.pickle, read back with loadfile; the
  logic itself needs no MacroQuest, so it is tested offline with a stand-in for mq.pickle.

  Each character writes its own file (learned_<server>_<name>.lua in the data folder), so two
  game windows never overwrite each other; every character reads all the files, so usage on one
  character ranks suggestions on all of them.

  Data:  cmds[word]          = {n = uses, t = last use, w = word as typed}
         args[context][word] = same; context = "<command>|<argument number>|<previous word>"
         lines               = last lines sent, oldest first (own file only)
  "Last use" is os.time(), a date: it is saved and compared across game sessions, which
  mq.gettime() (milliseconds since this game client started) can't do.
]]
local okMq, mq = pcall(require, 'mq')

local M = {}
M.__index = M

local MAX_LINES = 300
local MAX_PER_CONTEXT = 60

local function empty() return { version = 1, cmds = {}, args = {}, lines = {} } end

---@param opts {dir:string, me:string, now?:(fun():number), write?:(fun(path:string, data:table))}
function M.new(opts)
    local self = setmetatable({}, M)
    self.dir = opts.dir
    self.me = opts.me
    self.now = opts.now or os.time
    self.write = opts.write or (okMq and mq.pickle) or nil
    self.own = empty()
    self.others = empty()
    self.dirty = false
    self.changedAt = 0
    return self
end

---A table saved with mq.pickle (a Lua file returning it), or nil when missing or unreadable.
function M.readFile(path)
    local chunk = loadfile(path)
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

---Loads this character's file. listFiles(dir) -> names in the folder, used to read the others.
function M:load(listFiles)
    self.own = sane(M.readFile(self:ownPath()))
    self:loadOthers(listFiles)
end

---Re-reads the other characters' files (sums them into self.others).
function M:loadOthers(listFiles)
    local others = empty()
    if listFiles then
        local mine = 'learned_' .. self.me .. '.lua'
        for _, name in ipairs(listFiles(self.dir) or {}) do
            if name:match('^learned_.+%.lua$') and name:lower() ~= mine:lower() then
                local d = sane(M.readFile(self.dir .. '/' .. name))
                for k, e in pairs(d.cmds) do M.add(others.cmds, k, e) end
                for ctx, words in pairs(d.args) do
                    if type(words) == 'table' then
                        others.args[ctx] = others.args[ctx] or {}
                        for k, e in pairs(words) do M.add(others.args[ctx], k, e) end
                    end
                end
            end
        end
    end
    self.others = others
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
    if self.dirty and self.now() - self.changedAt >= (after or 5) then return self:save() end
    return true
end

local function touch(self)
    self.dirty = true
    self.changedAt = self.now()
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

---Merged (own + other characters) entries for command words: map word -> {n, t, w}
function M:commands()
    local out = {}
    for k, e in pairs(self.others.cmds) do M.add(out, k, e) end
    for k, e in pairs(self.own.cmds) do M.add(out, k, e) end
    return out
end

---Merged entries for one argument context.
function M:argsFor(cmd, argNo, prev)
    local key = M.contextKey(cmd, argNo, prev)
    local out = {}
    for k, e in pairs(self.others.args[key] or {}) do M.add(out, k, e) end
    for k, e in pairs(self.own.args[key] or {}) do M.add(out, k, e) end
    return out
end

---Merged entries for an argument position whatever came before it (a weaker hint).
function M:argsAt(cmd, argNo)
    local prefix = (cmd or ''):lower() .. '|' .. tostring(argNo) .. '|'
    local out = {}
    for _, src in ipairs({ self.others.args, self.own.args }) do
        for key, words in pairs(src) do
            if key:sub(1, #prefix) == prefix then
                for k, e in pairs(words) do M.add(out, k, e) end
            end
        end
    end
    return out
end

function M:clear()
    self.own = empty()
    touch(self)
end

return M
