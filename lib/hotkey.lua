--[[
  A key that opens the box on a fresh line starting with "/" (e.g. shift+/).

  Lua can't register key binds, so this uses MacroQuest's: a MQ2CustomBinds bind named "eqac"
  whose command is
      /docommand ${If[${Lua.Script[eq-autocomplete].Status.Equal[RUNNING]},/eqac slash,/lua run eq-autocomplete slash]}
  (stored with /noparse, so the ${...} is worked out on each key press: when the script isn't
  running the key starts it), and /bind eqac <key>.

  Plain "/" also belongs to MQ2ChatWnd's bind MQ2CSCHAT (MacroQuest.ini MQ2CSCHAT_Nrm=/); taking
  "/" clears that, any other key leaves it alone.

  The binds are saved in MacroQuest.ini and MQ2CustomBinds.txt (all characters), but a game
  window reads them only when it starts, so init.lua has every running copy apply the shared
  setting to its own window.
]]
local mq = require('mq')

local M = {}

M.BIND = 'eqac'
M.CHAT_BIND = 'MQ2CSCHAT'
M.COMMAND = '/docommand ${If[${Lua.Script[eq-autocomplete].Status.Equal[RUNNING]},/eqac slash,'
    .. '/lua run eq-autocomplete slash]}'
M.PLAIN = '/eqac slash'

---Reads an ini file: the value of section/key, or (key nil) whether the section exists.
local function ini(file, section, key)
    local f = io.open(mq.configDir .. '/' .. file, 'r')
    if not f then return nil end
    local inside, found = false, nil
    for line in f:lines() do
        local s = line:match('^%s*%[(.-)%]')
        if s then
            inside = s:lower() == section:lower()
            if inside and not key then found = true; break end
        elseif inside and key then
            local k, v = line:match('^%s*([^=]-)%s*=%s*(.-)%s*$')
            if k and k:lower() == key:lower() then found = v; break end
        end
    end
    f:close()
    return found
end

-- MQ2CustomBinds saves to MQ2CustomBinds.txt, one block per bind (checked 2026-11-23):
--   name=eqac / down=<command> / up=<command>
-- Returns whether the bind is there, and its down command.
local function customBind(name)
    local f = io.open(mq.configDir .. '/MQ2CustomBinds.txt', 'r')
    if not f then return false, nil end
    local current, found, down = nil, false, nil
    for line in f:lines() do
        local k, v = line:match('^%s*(%a+)%s*=(.*)$')
        if k then
            k = k:lower()
            if k == 'name' then
                current = v:match('^%s*(.-)%s*$'):lower()
                if current == name:lower() then found = true end
            elseif k == 'down' and current == name:lower() then
                down = v
            end
        end
    end
    f:close()
    return found, down
end

---What the files say now: key (our bind's key), exists/command (the custom bind and its command),
---chat (MQ2CSCHAT's key).
function M.saved()
    local exists, command = customBind(M.BIND)
    return {
        key = ini('MacroQuest.ini', 'Key Binds', M.BIND .. '_Nrm'),
        exists = exists,
        command = command,
        chat = ini('MacroQuest.ini', 'Key Binds', M.CHAT_BIND .. '_Nrm'),
    }
end

---The commands that give `key` to the box (key nil: take it away again).
---@param key string|nil e.g. "shift+/"
---@param chatWas string the key MQ2CSCHAT had before "/" was taken ("/")
---@return string[]
function M.steps(key, chatWas)
    local s = M.saved()
    local out = {}
    if key then
        if not s.exists then out[#out + 1] = '/custombind add ' .. M.BIND end
        out[#out + 1] = '/noparse /custombind set ' .. M.BIND .. ' ' .. M.COMMAND
        out[#out + 1] = '/bind ' .. M.BIND .. ' ' .. key
        if key == '/' then
            out[#out + 1] = '/bind ' .. M.CHAT_BIND .. ' clear'
        elseif s.chat == 'clear' then
            out[#out + 1] = '/bind ' .. M.CHAT_BIND .. ' ' .. chatWas  -- an earlier "/" took it
        end
    else
        out[#out + 1] = '/bind ' .. M.BIND .. ' clear'
        if s.exists then out[#out + 1] = '/custombind delete ' .. M.BIND end
        if s.chat == 'clear' then out[#out + 1] = '/bind ' .. M.CHAT_BIND .. ' ' .. chatWas end
    end
    return out
end

return M
