--[[
  The suggestion engine: given the text in the box and the cursor, what could the word being typed
  become, best first. Pure Lua: the game is reached only through the `sources` object, so
  tests\run.ps1 can drive it with a fake.

  sources (see lib/sources.lua for the real one):
    sources:get(kind)          -> {{w = value, d = description?, b = bonus?}, ...}  live values
    sources:pluginLoaded(name) -> bool          is a command's plugin there
    sources:aliases()          -> {['/t'] = '/tell', ...}   MacroQuest.ini [Aliases]
    sources:classShort()       -> 'SHD'          (optional) this character's class
  A live value may carry m = another name to match on (a zone's long name).
]]
local grammar = require('eq-autocomplete.lib.grammar')

local M = {}
M.__index = M

local MAX_ITEMS = 40

-- how much each kind of suggestion counts before usage is added
local BASE = {
    keyword = 20, names = 18, scripts = 16, running = 16, macros = 15, plugins = 15, spells = 15,
    items = 14, abilities = 14, discs = 14, buffs = 14, dngroups = 14, aliases = 12, learned = 13, zones = 15,
    spawns = 6, command = 0, alias = 3,
}

local function lower(s) return (s or ''):lower() end

local function copySeq(t)
    local out = {}
    for i, v in ipairs(t or {}) do out[i] = v end
    return out
end

---@param opts {commands:table, extras:table, learn:table, sources:table, now?:fun():number}
function M.new(opts)
    local self = setmetatable({}, M)
    self.learn = opts.learn
    self.sources = opts.sources
    self.now = opts.now or os.time  -- a date, compared with the "last used" dates in learned files
    local extras = opts.extras or {}
    self.extras = extras

    -- the command list: generated, plus extras (new commands, or grammar lines added)
    local db = {}
    for name, c in pairs((opts.commands or {}).commands or {}) do
        db[name] = { p = c.p, d = c.d, a = c.a, s = copySeq(c.s), g = copySeq(c.g) }
    end
    for name, x in pairs(extras.commands or {}) do
        local c = db[name]
        if not c then
            c = { p = x.p or 'MacroQuest', d = x.d or '', a = x.a, s = {}, g = {} }
            db[name] = c
        end
        if x.d and c.d == '' then c.d = x.d end
        for _, s in ipairs(x.s or {}) do c.s[#c.s + 1] = s end
        -- extras go first: they are what people actually type, so their keywords lead the list
        for i, seq in ipairs(x.g or {}) do table.insert(c.g, i, seq) end
    end
    self.db = db

    self.alias = {}   -- '/nav' -> '/navigate'
    self.names = {}   -- sorted command names
    for name, c in pairs(db) do
        self.names[#self.names + 1] = name
        for _, a in ipairs(c.a or {}) do
            if not db[a] then self.alias[a] = name end
        end
    end
    table.sort(self.names)

    self.common = {}
    for _, name in ipairs(extras.common or {}) do self.common[name] = true end
    return self
end

-- -----------------------------------------------------------------------------------------
-- Commands

-- "/${Me.Class.ShortName}" (CWTN aliases broadcast it so each character runs its own class
-- command) stands for this character's class command.
function M:classWord(word)
    if word:lower():find('me%.class%.shortname') and self.sources.classShort then
        local c = self.sources:classShort()
        if c then return '/' .. c:lower() end
    end
    return word
end

---Is a command usable right now (its plugin loaded)?
function M:available(c)
    local p = c.p
    -- KissAssist's and RGMercs' commands are always offered: without the script running they
    -- just do nothing
    if p == 'EverQuest' or p == 'MacroQuest' or p == 'KissAssist' or p == 'RGMercs' then return true end
    return self.sources:pluginLoaded(p)
end

---Finds the command a typed word means: its entry (nil when unknown), its canonical name (the
---word itself when unknown), and the words an alias puts before what is typed.
---@return table|nil entry
---@return string canonical
---@return string[] extra
function M:resolve(word, depth)
    depth = depth or 0
    local w = lower(self:classWord(word))
    if w:sub(1, 1) ~= '/' then w = '/' .. w end
    if self.db[w] then return self.db[w], w, {} end
    if self.alias[w] then return self.db[self.alias[w]], self.alias[w], {} end
    local userAliases = self.sources:aliases() or {}
    local expansion = userAliases[w]
    if expansion and depth < 3 then
        local toks = grammar.tokenize(expansion)
        if toks[1] then
            local entry, canon, extra = self:resolve(toks[1].value, depth + 1)
            local words = copySeq(extra)
            for i = 2, #toks do words[#words + 1] = self:classWord(toks[i].value) end
            -- an alias for a command that runs another (/cwtn = /dgge /docommand /shd): what you
            -- type after it belongs to the innermost command
            for _ = 1, 4 do
                if not entry or #words == 0 then break end
                local ctx = grammar.walk(entry.g, words)
                if not (ctx.nested and ctx.nested <= #words) then break end
                local inner, innerCanon, innerExtra = self:resolve(words[ctx.nested], depth + 1)
                if not inner then break end
                local rest = copySeq(innerExtra)
                for i = ctx.nested + 1, #words do rest[#rest + 1] = words[i] end
                entry, canon, words = inner, innerCanon, rest
            end
            return entry, canon, words
        end
    end
    -- EverQuest accepts abbreviations: take the shortest command that starts with the word
    if #w >= 3 then
        local best
        for _, name in ipairs(self.names) do
            if name:sub(1, #w) == w and (not best or #name < #best) then best = name end
        end
        if best then return self.db[best], best, {} end
    end
    return nil, w, {}
end

-- -----------------------------------------------------------------------------------------
-- Scoring

function M:usageBonus(e, weight)
    if not e then return 0 end
    local age = self.now() - (e.t or 0)
    local recent = age < 3600 and 6 or age < 86400 and 4 or age < 7 * 86400 and 2 or 0
    return (12 * math.log(1 + e.n) + recent) * (weight or 1)
end

local function addCandidate(list, index, w, kind, d, score, extra)
    local k = lower(w)
    local c = index[k]
    if c then
        if score > c.score then c.score = score end
        if (not c.d or c.d == '') and d then c.d = d end
        return c
    end
    c = { w = w, kind = kind, d = d, score = score, order = #list + 1 }
    if extra then for key, v in pairs(extra) do c[key] = v end end
    index[k] = c
    list[#list + 1] = c
    return c
end

-- keeps the candidates matching what is typed, scores and sorts them
local function rank(list, typed, cap)
    local t = lower(typed)
    local out = {}
    for _, c in ipairs(list) do
        local w = lower(c.w)
        if t == '' or w:sub(1, #t) == t then
            c.prefix = true
            if w == t then c.score = c.score + 100 end  -- fully typed: Tab just moves on
            out[#out + 1] = c
        elseif #t >= 2 and (w:find(t, 1, true) or (c.m and c.m:find(t, 1, true))) then
            -- inside the word, or in its other name (a zone's long name)
            c.prefix = false
            c.score = c.score - 40
            out[#out + 1] = c
        end
    end
    table.sort(out, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        local commands = a.w:sub(1, 1) == '/' and b.w:sub(1, 1) == '/'
        if commands then
            -- commands: shortest first (EverQuest takes abbreviations), then alphabetical
            if #a.w ~= #b.w then return #a.w < #b.w end
            return lower(a.w) < lower(b.w)
        end
        -- arguments: in the order the syntax and the sources give them
        return a.order < b.order
    end)
    while #out > (cap or MAX_ITEMS) do table.remove(out) end
    return out
end

-- -----------------------------------------------------------------------------------------
-- Suggestions

function M:commandCandidates(typed)
    local list, index = {}, {}
    local t = lower(typed)
    if t:sub(1, 1) ~= '/' then t = '/' .. t end
    local first = t:sub(1, 2)  -- cheap pre-filter: same first letter, or contains for longer input
    local function wanted(name)
        if #t < 2 then return true end  -- just "/": everything, best first
        return name:sub(1, 2) == first or (#t >= 3 and name:find(t:sub(2), 1, true)) ~= nil
    end
    for _, name in ipairs(self.names) do
        local c = self.db[name]
        if wanted(name) and self:available(c) then
            addCandidate(list, index, name, 'command', c.d, BASE.command + (self.common[name] and 6 or 0))
        end
    end
    for a, name in pairs(self.alias) do
        local c = self.db[name]
        if wanted(a) and self:available(c) then
            addCandidate(list, index, a, 'command', '= ' .. name .. ' - ' .. (c.d or ''),
                BASE.command + (self.common[name] and 6 or 0))
        end
    end
    for a, expansion in pairs(self.sources:aliases() or {}) do
        if wanted(a) then addCandidate(list, index, a, 'alias', 'alias: ' .. expansion, BASE.alias) end
    end
    for k, e in pairs(self.learn:commands()) do
        if wanted(k) then
            local c = addCandidate(list, index, e.w, 'learned', 'used before', BASE.learned)
            c.score = c.score + self:usageBonus(e)
            c.uses = (c.uses or 0) + e.n
        end
    end
    local typedWithSlash = typed:sub(1, 1) == '/' and typed or ('/' .. typed)
    return rank(list, typedWithSlash)
end

function M:sourceFor(cmdName, placeholder)
    local name = lower(placeholder)
    local per = (self.extras.commandSources or {})[cmdName]
    if per and per[name] ~= nil then return per[name] or nil end
    return (self.extras.sources or {})[name]
end

---@param text string
---@param cursor integer bytes before the cursor
---@return table result {items, token, cmd, cmdName, expect, offset}
function M:suggest(text, cursor, depth)
    depth = depth or 0
    cursor = math.max(0, math.min(cursor or #text, #text))
    local tokens, current = grammar.split(text, cursor)
    local result = { items = {}, token = current, expect = {} }

    if #tokens == 0 then
        if current.value == '' then return result end
        result.items = self:commandCandidates(current.value)
        return result
    end

    local entry, canon, extra = self:resolve(tokens[1].value)
    result.cmd, result.cmdName = entry, canon
    local words = copySeq(extra)
    for i = 2, #tokens do words[#words + 1] = tokens[i].value end

    local list, index = {}, {}
    if entry then
        local ctx = grammar.walk(entry.g, words)
        if ctx.nested and depth < 4 then
            -- the rest of the line is another command: complete it as one
            local tokenNo = ctx.nested - #extra + 1   -- 2 = first word after the command
            local start = (tokenNo <= #tokens) and tokens[tokenNo].s or current.s
            if tokenNo >= 2 then
                local sub = self:suggest(text:sub(start), cursor - start + 1, depth + 1)
                sub.token.s = sub.token.s + start - 1
                sub.token.e = sub.token.e + start - 1
                sub.outer = canon
                return sub
            end
        end
        result.expect = ctx.expect
        local typedSet = {}
        for _, w in ipairs(words) do typedSet[lower(w)] = true end
        for _, node in ipairs(ctx.expect) do
            local kw = grammar.keyword(node)
            if kw then
                addCandidate(list, index, kw, 'keyword', type(node) == 'table' and node.d or nil, BASE.keyword)
            else
                local kind = self:sourceFor(canon, node.v)
                if kind then
                    for _, v in ipairs(self.sources:get(kind) or {}) do
                        if v.w and v.w ~= '' then
                            addCandidate(list, index, v.w, kind, v.d, (BASE[kind] or 10) + (v.b or 0),
                                v.m and { m = v.m:lower() } or nil)
                        end
                    end
                end
            end
        end
        if #ctx.expect == 0 and not ctx.nested and not ctx.complete then
            -- what was typed doesn't fit the documented syntax: offer its keywords anyway, lower
            for _, kw in ipairs(grammar.keywords(entry.g)) do
                if not typedSet[lower(kw)] then addCandidate(list, index, kw, 'keyword', nil, BASE.keyword - 12) end
            end
        end
    end

    -- what you typed here before
    local argNo = #words + 1
    local prev = words[#words] or ''
    for _, pass in ipairs({ { self.learn:argsFor(canon, argNo, prev), 1 }, { self.learn:argsAt(canon, argNo), 0.4 } }) do
        for _, e in pairs(pass[1]) do
            local c = addCandidate(list, index, e.w, 'learned', nil, BASE.learned * pass[2])
            c.score = c.score + self:usageBonus(e, pass[2])
            if pass[2] == 1 then c.uses = (c.uses or 0) + e.n end
        end
    end

    result.items = rank(list, current.value)
    return result
end

-- -----------------------------------------------------------------------------------------
-- Completing

---The text that replaces the current word for a suggestion (quoted when it has spaces).
function M.insertText(item, token)
    local w = item.w
    if w:find(' ', 1, true) or (token and token.quoted) then
        if w:sub(1, 1) ~= '"' then w = '"' .. w .. '"' end
    end
    return w
end

---What a suggestion would add after what is typed (the grey text), or nil.
function M.ghost(text, cursor, result, item)
    if not item or cursor ~= #text then return nil end
    local tok = result.token
    local typed = text:sub(tok.s, cursor)
    local ins = M.insertText(item, tok)
    if #ins > #typed and lower(ins:sub(1, #typed)) == lower(typed) then
        return ins:sub(#typed + 1)
    end
    return nil
end

---Replaces the current word with a suggestion.
---@return string text, integer cursor (bytes before it)
function M.apply(text, result, item)
    local tok = result.token
    local before = text:sub(1, tok.s - 1)
    local after = text:sub(tok.e + 1)
    local ins = M.insertText(item, tok)
    if after == '' then ins = ins .. ' ' end
    return before .. ins .. after, #before + #ins
end

-- -----------------------------------------------------------------------------------------
-- Learning

---Remembers a line that was sent: the command word, each argument in its place, the line.
function M:record(line, depth)
    depth = depth or 0
    local tokens = grammar.tokenize(line)
    if #tokens == 0 then return end
    local word = tokens[1].value
    if word:sub(1, 1) ~= '/' or #word < 2 then return end
    if depth == 0 then self.learn:addLine(line) end
    self.learn:useCommand(word)
    local entry, canon, extra = self:resolve(word)
    local words = copySeq(extra)
    for i = 2, #tokens do words[#words + 1] = tokens[i].value end
    for i = #extra + 1, #words do
        if entry then
            local before = {}
            for j = 1, i - 1 do before[j] = words[j] end
            local ctx = grammar.walk(entry.g, before)
            if ctx.nested and ctx.nested <= i and depth < 4 then
                local tokenNo = ctx.nested - #extra + 1
                if tokenNo >= 2 and tokens[tokenNo] then self:record(line:sub(tokens[tokenNo].s), depth + 1) end
                return
            end
            local onlyText = #ctx.expect > 0
            for _, node in ipairs(ctx.expect) do
                if grammar.keyword(node) or grammar.restKind(node.v) ~= 'text' then onlyText = false end
            end
            if onlyText then return end  -- free text (a message): not worth suggesting word by word
        end
        self.learn:useArg(canon, i, words[i - 1] or '', words[i])
    end
end

return M
