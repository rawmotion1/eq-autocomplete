--[[
  A key that opens the box, ready to type (e.g. shift+/).

  Lua can't register key binds, so this uses MacroQuest's: a MQ2CustomBinds bind named "eqac"
  whose command is
      /docommand ${If[${Lua.Script[eq-autocomplete].Status.Equal[RUNNING]},/eqac show,/lua run eq-autocomplete show]}
  (stored with /noparse, so the ${...} is worked out on each key press: when the script isn't
  running the key starts it), and /bind eqac <key>.

  Plain "/" can't be used: EverQuest's chat window opens on it anyway.

  MacroQuest saves the binds in MacroQuest.ini and MQ2CustomBinds.txt, for every character, and
  that is the only record of the key. A game window reads those files only when the game starts,
  so when the script starts it applies the saved key to its own window (M.saved()).

  MQ2CustomBinds ships with MacroQuest and is loaded by default, but it can be unloaded. Before
  any of this it is checked, and if it isn't loaded it is loaded with "noauto": for this session
  only, so the plugins MacroQuest.ini loads at start are left as the user set them.
]]
local mq = require('mq')

local M = {}

M.PLUGIN = "MQ2CustomBinds"
M.BIND = "eqac"
M.COMMAND = "/docommand ${If[${Lua.Script[eq-autocomplete].Status.Equal[RUNNING]},/eqac show,"
    .. "/lua run eq-autocomplete show]}"

---The commands that give `key` to the box, or (key nil) take it away. A `quiet` step is always
---squelched: "/custombind add" answers "name in use" when the bind is already there, which is fine.
---@param key string|nil e.g. "shift+/"
---@return {cmd:string, quiet:boolean|nil}[]
function M.steps(key)
    if key then
        return {
            { cmd = "/custombind add " .. M.BIND, quiet = true },
            { cmd = "/noparse /custombind set " .. M.BIND .. " " .. M.COMMAND },
            { cmd = "/bind " .. M.BIND .. " " .. key },
        }
    end
    return {
        { cmd = "/bind " .. M.BIND .. " clear" },
        { cmd = "/custombind delete " .. M.BIND },
    }
end

---The key MacroQuest.ini holds for the bind ([Key Binds] eqac_Nrm), or nil when there is none.
---@return string|nil
function M.saved()
    local ok, key = pcall(function()
        return mq.TLO.Ini.File(mq.configDir .. '/MacroQuest.ini').Section('Key Binds').Key(M.BIND .. '_Nrm').Value()
    end)
    if ok and type(key) == 'string' and key ~= '' and key:lower() ~= 'clear' then return key end
    return nil
end

local function pluginLoaded()
    local ok, loaded = pcall(function() return mq.TLO.Plugin(M.PLUGIN).IsLoaded() end)
    return ok and loaded == true
end

---Makes sure MQ2CustomBinds is loaded, loading it "noauto" if it isn't. Waits for it, so call it
---from the main loop only. Returns ok, and whether it was loaded just now.
---@return boolean ok, boolean loadedNow
function M.ensurePlugin()
    if pluginLoaded() then return true, false end
    mq.cmd("/squelch /plugin " .. M.PLUGIN .. " load noauto")
    mq.delay(2000, pluginLoaded)
    local ok = pluginLoaded()
    return ok, ok
end

---`cmd` with MacroQuest's replies squelched (/noparse stays first so the ${...} is kept as text).
function M.squelched(cmd)
    if cmd:find("^/noparse ") then return "/noparse /squelch " .. cmd:sub(10) end
    return "/squelch " .. cmd
end

return M
