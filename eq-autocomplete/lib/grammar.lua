--[[
  Tokenizer and grammar walker. Pure Lua, no MacroQuest: tested offline by tests\run.ps1.

  A grammar (lib/commands.lua, lib/extras.lua) is a list of alternatives; each alternative is a
  sequence of nodes:
    "word"                      a literal keyword
    {k="word", d="text"}        the same, with a description for the suggestion list
    {v="name", q=1}             a placeholder (q = the docs show it quoted)
    {alt={seq, ...}, o=1, r=1}  a choice; o = optional, r = may repeat

  walk() feeds the words typed so far through the grammar and reports what may come next.
]]
local M = {}

-- Placeholders that swallow the rest of the line.
--   'command' kind: the rest is another command (/dex Name /nav spawn X), completed as such.
--   'text' kind: free text (/tell Name <message>); nothing to suggest but what was typed before.
local REST = {
    ['command'] = 'command', ['commands'] = 'command', ['cmd'] = 'command',
    ['/command|text'] = 'command', ['command text'] = 'command', ['trigger text | command text'] = 'command',
    ['text'] = 'text', ['message'] = 'text', ['comment'] = 'text', ['custom note'] = 'text',
    ['link text'] = 'text', ['string'] = 'text', ['str'] = 'text', ['formula'] = 'text',
    ['condition'] = 'text', ['lua code'] = 'text', ['args'] = 'text', ['parameters'] = 'text',
}

---@param name string placeholder name as in the grammar
---@return string|nil 'command', 'text' or nil
function M.restKind(name)
    return REST[(name or ''):lower()]
end

---Splits a line into words. Double quotes group words ("Spirit of the Wolf" is one token).
---@param text string
---@return table[] tokens {s=first byte, e=last byte, text=raw, value=without quotes, quoted=bool, open=bool}
function M.tokenize(text)
    local tokens = {}
    local i, n = 1, #text
    while i <= n do
        local c = text:sub(i, i)
        if c == ' ' or c == '\t' then
            i = i + 1
        elseif c == '"' then
            local close = text:find('"', i + 1, true)
            local e = close or n
            -- a closing quote may be followed by more characters: "foo"bar is one token
            if close then
                local stop = text:find('[ \t]', close + 1)
                e = stop and stop - 1 or n
            end
            local raw = text:sub(i, e)
            tokens[#tokens + 1] = {
                s = i, e = e, text = raw, quoted = true, open = close == nil,
                value = raw:gsub('"', ''),
            }
            i = e + 1
        else
            local stop = text:find('[ \t]', i)
            local e = stop and stop - 1 or n
            local raw = text:sub(i, e)
            -- a quote inside a word ("/cast "Spirit of" typed as /cast Spirit"...) is rare: keep it simple
            local q = raw:find('"', 1, true)
            if q then
                local close = text:find('"', i + q, true)
                if close then
                    local stop2 = text:find('[ \t]', close + 1)
                    e = stop2 and stop2 - 1 or n
                else
                    e = n
                end
                raw = text:sub(i, e)
                tokens[#tokens + 1] = { s = i, e = e, text = raw, value = raw:gsub('"', ''), quoted = true, open = close == nil }
            else
                tokens[#tokens + 1] = { s = i, e = e, text = raw, value = raw, quoted = false, open = false }
            end
            i = e + 1
        end
    end
    return tokens
end

---The word being typed at the cursor: the token the cursor is in or just after, or an empty
---token when the cursor follows a space. Returns the finished tokens before it, and it.
---@param text string
---@param cursor integer bytes before the cursor (0 = start)
---@return table[] done
---@return table current {s, e, text, value, quoted, open}
function M.split(text, cursor)
    local before = text:sub(1, cursor)
    local tokens = M.tokenize(before)
    local last = tokens[#tokens]
    local current
    if last and last.e == #before then
        current = table.remove(tokens)
    else
        current = { s = #before + 1, e = #before, text = '', value = '', quoted = false, open = false }
    end
    -- the current word extends past the cursor up to the next space (completion replaces all of it)
    if not current.open then
        local stop = text:find('[ \t]', cursor + 1)
        current.e = stop and stop - 1 or #text
        if current.e < current.s - 1 then current.e = current.s - 1 end
    else
        current.e = #text
    end
    return tokens, current
end

local function lower(s) return (s or ''):lower() end

---The keyword a node stands for, or nil when it isn't one ("word" or {k = "word"}).
function M.keyword(node)
    if type(node) == 'string' then return node end
    return node.k
end

---Walks a grammar over the words typed so far.
---@param alts table[] the command's grammar (list of alternative sequences)
---@param words string[] values of the finished words after the command word
---@return table result {expect = {node...}, nested = index into words of a typed word that starts a
---nested command (or nil), nestedNext = the word being typed (after them) would start one if it is a
---command, complete = the words so far are a whole command}
function M.walk(alts, words)
    local n = #words
    local ctx = { expect = {}, seen = {}, nested = nil }
    local memo = {}

    local function addExpect(node)
        local kw = M.keyword(node)
        local key = kw and ('k:' .. lower(kw)) or ('v:' .. lower(node.v))
        if not ctx.seen[key] then
            ctx.seen[key] = true
            ctx.expect[#ctx.expect + 1] = node
        end
    end

    local walkSeq

    -- returns a list (set as keys) of word indexes reachable after the node, starting at word ti
    local function walkNode(node, ti)
        local kw = M.keyword(node)
        if kw then
            if ti > n then addExpect(node); return {} end
            if lower(words[ti]) == lower(kw) then return { [ti + 1] = true } end
            return {}
        end
        if node.v then
            local rest = M.restKind(node.v)
            if rest == 'command' then
                -- a nested command starts here only if the word here is one ("/..."), as DanNet
                -- reads it: "/dge /sit" sends /sit to all, "/dge healers /sit" to a group. The
                -- word being typed is the caller's to decide (nestedNext).
                if ti > n then
                    ctx.nestedNext = true
                elseif words[ti]:sub(1, 1) == '/' and (not ctx.nested or ti < ctx.nested) then
                    ctx.nested = ti
                end
                return {}
            elseif rest == 'text' then
                if ti > n then addExpect(node) end
                return {}  -- free text runs to the end of the line, the current word included
            end
            if ti > n then addExpect(node); return {} end
            return { [ti + 1] = true }
        end
        -- a choice
        local out = {}
        if node.o then out[ti] = true end
        local frontier = { [ti] = true }
        local guard = 0
        while next(frontier) and guard <= n + 1 do
            guard = guard + 1
            local nextFrontier = {}
            for start in pairs(frontier) do
                for _, seq in ipairs(node.alt or {}) do
                    for e in pairs(walkSeq(seq, 1, start)) do
                        if not out[e] then
                            out[e] = true
                            if node.r and e > start then nextFrontier[e] = true end
                        end
                    end
                end
            end
            frontier = nextFrontier
        end
        return out
    end

    walkSeq = function(seq, pos, ti)
        local m = memo[seq]
        if not m then m = {}; memo[seq] = m end
        local key = pos * 1000 + ti
        if m[key] then return m[key] end
        local result
        if pos > #seq then
            result = { [ti] = true }
        else
            result = {}
            for e in pairs(walkNode(seq[pos], ti)) do
                for r in pairs(walkSeq(seq, pos + 1, e)) do result[r] = true end
            end
        end
        m[key] = result
        return result
    end

    local complete = false
    for _, seq in ipairs(alts or {}) do
        local ends = walkSeq(seq, 1, 1)
        if ends[n + 1] then complete = true end
    end
    ctx.complete = complete  -- the words typed so far form a whole command (nothing more needed)
    return ctx
end

---Every keyword anywhere in a grammar (the fallback when the typed words don't fit it).
---@param alts table[]
---@return string[]
function M.keywords(alts)
    local out, seen = {}, {}
    local function visit(node)
        local kw = M.keyword(node)
        if kw then
            if not seen[lower(kw)] then seen[lower(kw)] = true; out[#out + 1] = kw end
        elseif node.alt then
            for _, seq in ipairs(node.alt) do for _, x in ipairs(seq) do visit(x) end end
        end
    end
    for _, seq in ipairs(alts or {}) do for _, x in ipairs(seq) do visit(x) end end
    return out
end

return M
