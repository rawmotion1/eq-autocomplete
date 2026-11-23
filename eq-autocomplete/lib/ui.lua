--[[
  The floating input box and its suggestion list (ImGui).

  Keys while typing:
    Tab, or Right arrow at the end of the line   complete the word with the highlighted suggestion
    Up / Down                                    move through the suggestions; with none showing,
                                                 step through the lines you sent before
    Enter                                        send the line to MacroQuest
    Escape                                       clear the line (again: leave the box)
  The grip on the left moves the box; right-click it for options.
]]
local ImGui = require('ImGui')
local Engine = require('eq-autocomplete.lib.engine')

local M = {}
M.__index = M

local WINDOW = 'eq-autocomplete##eqac'
local POPUP = '##eqac_suggestions'

---@param opts {engine:table, learn:table, sources:table, settings:table, saveSettings:fun(), send:fun(line:string)}
function M.new(opts)
    local self = setmetatable({}, M)
    for k, v in pairs(opts) do self[k] = v end
    self.open = true
    self.text = ''
    self.cursor = 0
    self.prevCursor = 0
    self.result = { items = {}, token = { s = 1, e = 0 } }
    self.resultText, self.resultCursor, self.resultVersion = nil, nil, -1
    self.sel = 1
    self.top = 1
    self.hist, self.histText = nil, nil
    self.focusNext = false
    self.pendingEdit = nil
    self.active = false
    self.popupHovered = false
    self.callback = function(a, b) return self:onInput(b or a) end
    return self
end

-- -----------------------------------------------------------------------------------------
-- state

function M:rows() return math.max(3, math.min(20, tonumber(self.settings.rows) or 8)) end

function M:items()
    if self.hist then return {} end
    return self.result.items
end

function M:selected() return self:items()[self.sel] end

function M:refresh(force)
    local same = self.resultText == self.text and self.resultCursor == self.cursor
    -- fresh lists (spawns, names) only matter while you are typing; otherwise they'd keep being rebuilt
    if not force and same and (self.resultVersion == self.sources.version or not self.active) then
        return
    end
    local keep = (self.resultText == self.text) and self:selected()
    self.result = self.engine:suggest(self.text, self.cursor)
    self.resultText, self.resultCursor, self.resultVersion = self.text, self.cursor, self.sources.version
    self.sel = 1
    if keep then
        for i, it in ipairs(self.result.items) do
            if it.w == keep.w then self.sel = i; break end
        end
    end
    self:keepVisible()
end

function M:keepVisible()
    local n = #self:items()
    local rows = self:rows()
    if self.sel < self.top then self.top = self.sel end
    if self.sel > self.top + rows - 1 then self.top = self.sel - rows + 1 end
    self.top = math.max(1, math.min(self.top, math.max(1, n - rows + 1)))
end

function M:moveSel(delta)
    local n = #self:items()
    if n == 0 then return end
    self.sel = ((self.sel - 1 + delta) % n) + 1
    self:keepVisible()
end

-- replaces the whole text inside an InputText callback
local function setBuffer(data, text, cursor)
    data:DeleteChars(0, #data.Buffer)
    if text ~= '' then data:InsertChars(0, text) end
    data.CursorPos = cursor
    data.SelectionStart = cursor
    data.SelectionEnd = cursor
end

-- -----------------------------------------------------------------------------------------
-- keys (InputText callback: ImGui calls one of these per frame while the box has focus)

function M:accept(data)
    local text, cursor = data.Buffer, data.CursorPos
    local result, item
    if text == self.resultText and cursor == self.resultCursor then
        result, item = self.result, self:selected()
    else
        result = self.engine:suggest(text, cursor)
        item = result.items[1]
    end
    if not item then return false end
    local newText, newCursor = Engine.apply(text, result, item)
    setBuffer(data, newText, newCursor)
    self.cursor, self.prevCursor = newCursor, newCursor
    return true
end

function M:recall(data, up)
    local lines = self.learn:lines()
    if #lines == 0 then return end
    if up then
        self.hist = self.hist and math.max(1, self.hist - 1) or #lines
    else
        if not self.hist then return end
        self.hist = self.hist + 1
        if self.hist > #lines then
            self.hist, self.histText = nil, nil
            setBuffer(data, '', 0)
            return
        end
    end
    local line = lines[self.hist]
    self.histText = line
    setBuffer(data, line, #line)
end

function M:onInput(data)
    local flag = data.EventFlag
    if flag == ImGuiInputTextFlags.CallbackAlways then
        if self.pendingEdit then
            setBuffer(data, self.pendingEdit.text, self.pendingEdit.cursor)
            self.pendingEdit = nil
        end
        local len = #data.Buffer
        -- Right arrow completes only when the cursor was already at the end of the line
        if ImGui.IsKeyPressed(ImGuiKey.RightArrow) and self.prevCursor == len and data.CursorPos == len
            and not data:HasSelection() then
            self:accept(data)
        end
        self.cursor = data.CursorPos
        self.prevCursor = data.CursorPos
    elseif flag == ImGuiInputTextFlags.CallbackCompletion then
        self:accept(data)
    elseif flag == ImGuiInputTextFlags.CallbackHistory then
        local up = data.EventKey == ImGuiKey.UpArrow
        if #self:items() > 0 then
            self:moveSel(up and -1 or 1)
        else
            self:recall(data, up)
        end
    end
    return 0
end

-- -----------------------------------------------------------------------------------------
-- drawing

function M:submit(line)
    line = line:gsub('^%s+', ''):gsub('%s+$', '')
    if line == '' then return end
    if line:sub(1, 1) ~= "/" then line = "/" .. line end
    self.engine:record(line)
    self.send(line)
end

-- MacroQuest's ImGui binding returns some positions and sizes as two numbers and some as one
-- ImVec2: GetMouseDragDelta gives an ImVec2 in game (2026-11-23) although mq-definitions says
-- two numbers. Everything read here goes through xy() so either form works.
local function xy(a, b)
    if type(a) == 'number' then return a, (type(b) == 'number' and b or 0) end
    if a ~= nil then return a.x or 0, a.y or 0 end
    return 0, 0
end

local function grip(self)
    local h = ImGui.GetFrameHeight()
    ImGui.PushStyleColor(ImGuiCol.Button, 0, 0, 0, 0)
    ImGui.Button('::##eqac_grip', h * 0.6, h)
    ImGui.PopStyleColor()
    if ImGui.IsItemActive() and ImGui.IsMouseDragging(ImGuiMouseButton.Left) and not self.settings.locked then
        local dx, dy = xy(ImGui.GetMouseDragDelta(ImGuiMouseButton.Left))
        local x, y = xy(ImGui.GetWindowPos())
        ImGui.SetWindowPos(x + dx, y + dy)
        ImGui.ResetMouseDragDelta(ImGuiMouseButton.Left)
    end
    if ImGui.IsItemHovered() and not ImGui.IsItemActive() then
        ImGui.SetTooltip(self.settings.locked and 'Locked. Right-click for options.' or 'Drag to move. Right-click for options.')
    end
    if ImGui.BeginPopupContextItem('##eqac_menu') then
        local s = self.settings
        local changed = false
        local _, v
        _, v = ImGui.MenuItem('Keep focus after Enter', nil, s.keepFocus); if v ~= s.keepFocus then s.keepFocus = v; changed = true end
        _, v = ImGui.MenuItem('Show command syntax', nil, s.showSyntax); if v ~= s.showSyntax then s.showSyntax = v; changed = true end
        _, v = ImGui.MenuItem('Lock position and size', nil, s.locked); if v ~= s.locked then s.locked = v; changed = true end
        if ImGui.BeginMenu('Rows in the list') then
            for _, n in ipairs({ 5, 8, 12, 16 }) do
                if ImGui.MenuItem(tostring(n), nil, s.rows == n) then s.rows = n; changed = true end
            end
            ImGui.EndMenu()
        end
        ImGui.Separator()
        if ImGui.MenuItem('Hide (/eqac to show)') then self.open = false end
        if changed then self.saveSettings() end
        ImGui.EndPopup()
    end
end

-- grey preview of the highlighted suggestion after the cursor
local function ghost(self, minX, minY, maxX)
    local item = self:selected()
    if not item or not self.active then return end
    local rest = Engine.ghost(self.text, self.cursor, self.result, item)
    if not rest then return end
    local pad = ImGui.GetStyle().FramePadding
    local typedW = (xy(ImGui.CalcTextSize(self.text)))
    local restW = (xy(ImGui.CalcTextSize(rest)))
    local x = minX + pad.x + typedW
    if x + restW > maxX - pad.x then return end  -- the box has scrolled or is too narrow
    ImGui.GetWindowDrawList():AddText(ImVec2(x, minY + pad.y), ImGui.GetColorU32(ImGuiCol.TextDisabled, 1), rest)
end

local KIND_LABEL = {
    command = '', keyword = '', names = 'character', spawns = 'spawn', spells = 'spell', items = 'item',
    abilities = 'ability', discs = 'disc', buffs = 'buff', scripts = 'script', running = 'running',
    macros = 'macro', plugins = 'plugin', dngroups = 'group', aliases = 'alias', alias = '', learned = '',
    zones = 'zone',
}

local function describe(item)
    local d = item.d or KIND_LABEL[item.kind] or ''
    if d == '' and item.kind == 'keyword' then d = 'keyword' end
    if item.uses and item.uses > 0 then
        d = (d ~= '' and d ~= 'used before') and (d .. '  (' .. item.uses .. 'x)') or ('used ' .. item.uses .. 'x')
    end
    if #d > 90 then d = d:sub(1, 87) .. '...' end
    return d
end

local popupBody

local function popup(self, minX, minY, maxX, maxY)
    local items = self:items()
    local syntax = self.settings.showSyntax and self.result.cmd and self.result.cmd.s or nil
    if self.hist or (#items == 0 and not syntax) then
        self.popupHovered = false
        return
    end
    local style = ImGui.GetStyle()
    local fontSize = ImGui.GetFontSize()
    local width = math.max(maxX - minX, fontSize * 18)
    local display = ImGui.GetIO().DisplaySize
    local lineH = ImGui.GetTextLineHeightWithSpacing()
    local rows = math.min(#items, self:rows())
    local estH = (rows + (syntax and math.min(#syntax, 3) + 2 or 0)) * lineH + style.WindowPadding.y * 2
    local gap = style.ItemInnerSpacing.y
    local y = maxY + gap
    if y + estH > display.y and minY - estH - gap > 0 then y = minY - estH - gap end
    ImGui.SetNextWindowPos(minX, y)
    ImGui.SetNextWindowSizeConstraints(width, 0, math.max(width, fontSize * 45), display.y)
    ImGui.SetNextWindowBgAlpha(0.95)
    local flags = bit32.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoMove,
        ImGuiWindowFlags.NoSavedSettings, ImGuiWindowFlags.NoFocusOnAppearing, ImGuiWindowFlags.NoNav,
        ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoDocking)
    local _, show = ImGui.Begin(POPUP, nil, flags)
    if show then
        local ok, err = pcall(popupBody, self, items, rows, syntax)
        if not ok then self:report(err) end
    else
        self.popupHovered = false
    end
    ImGui.End()
end

function popupBody(self, items, rows, syntax)
    do
        local style = ImGui.GetStyle()
        local labelW = 0
        for i = self.top, math.min(#items, self.top + rows - 1) do
            labelW = math.max(labelW, (xy(ImGui.CalcTextSize(items[i].w))))
        end
        -- descriptions start one column gap after the widest name
        local descX = style.WindowPadding.x + labelW + style.ItemSpacing.x * 2
        for i = self.top, math.min(#items, self.top + rows - 1) do
            local item = items[i]
            local _, clicked = ImGui.Selectable(item.w .. '##eqac_item' .. i, i == self.sel)
            if clicked then
                self.sel = i
                local text, cursor = Engine.apply(self.text, self.result, item)
                self.text, self.cursor = text, cursor
                self.pendingEdit = { text = text, cursor = cursor }
                self.focusNext = true
            end
            local d = describe(item)
            if d ~= '' then
                ImGui.SameLine(descX)
                ImGui.TextDisabled(d)
            end
        end
        if #items > rows then
            ImGui.TextDisabled(string.format('%d-%d of %d', self.top, math.min(#items, self.top + rows - 1), #items))
        end
        if syntax then
            if #items > 0 then ImGui.Separator() end
            local outer = self.result.outer and (self.result.outer .. ' > ') or ''
            local d = self.result.cmd.d or ''
            ImGui.TextDisabled(outer .. (self.result.cmdName or '') .. (d ~= '' and ('  ' .. d) or ''))
            for i = 1, math.min(#syntax, 3) do ImGui.TextDisabled('  ' .. syntax[i]) end
            if #syntax > 3 then ImGui.TextDisabled(string.format('  (+%d more)', #syntax - 3)) end
        end
        self.popupHovered = ImGui.IsWindowHovered()
    end
end

---Prints a drawing error to the MQ console once (not every frame).
function M:report(err)
    err = tostring(err)
    if err ~= self.lastError then
        self.lastError = err
        print('\ar[eqac]\ax UI error (the box keeps running): ' .. err)
    end
end

function M:draw()
    if not self.open then return end
    local style = ImGui.GetStyle()
    local fontSize = ImGui.GetFontSize()
    local h = ImGui.GetFrameHeight() + style.WindowPadding.y * 2
    ImGui.SetNextWindowSize(fontSize * 33, h, ImGuiCond.FirstUseEver)
    ImGui.SetNextWindowSizeConstraints(fontSize * 11, h, ImGui.GetIO().DisplaySize.x, h)
    local flags = bit32.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoScrollbar,
        ImGuiWindowFlags.NoScrollWithMouse, ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.NoDocking)
    if self.settings.locked then flags = bit32.bor(flags, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize) end
    local _, show = ImGui.Begin(WINDOW, nil, flags)
    local ok, minX, minY, maxX, maxY = true, nil, nil, nil, nil
    if show then
        -- an error between Begin and End would leave End uncalled, which pauses all of ImGui
        ok, minX, minY, maxX, maxY = pcall(self.drawBox, self)
        if not ok then self:report(minX) end
    end
    ImGui.End()
    if show and ok and (self.active or self.popupHovered) then
        popup(self, minX, minY, maxX, maxY)
    else
        self.popupHovered = false
    end
end

function M:drawBox()
    local minX, minY, maxX, maxY
    do
        grip(self)
        ImGui.SameLine(0, ImGui.GetStyle().ItemInnerSpacing.x)
        ImGui.SetNextItemWidth(-1)
        if self.focusNext then
            ImGui.SetKeyboardFocusHere()
            self.focusNext = false
        end
        local inputFlags = bit32.bor(ImGuiInputTextFlags.EnterReturnsTrue, ImGuiInputTextFlags.CallbackCompletion,
            ImGuiInputTextFlags.CallbackHistory, ImGuiInputTextFlags.CallbackAlways, ImGuiInputTextFlags.EscapeClearsAll)
        local text, entered = ImGui.InputTextWithHint('##eqac_input', '/command   (Tab completes)', self.text, inputFlags,
            self.callback)
        self.active = ImGui.IsItemActive()
        minX, minY = xy(ImGui.GetItemRectMin())
        maxX, maxY = xy(ImGui.GetItemRectMax())

        if text ~= self.text then
            self.text = text or ''
            if self.cursor > #self.text then self.cursor = #self.text end
            if self.hist and self.text ~= self.histText then self.hist, self.histText = nil, nil end
        end
        if entered then
            local line = self.text
            self.text, self.cursor, self.prevCursor = '', 0, 0
            self.hist, self.histText = nil, nil
            self:submit(line)
            if self.settings.keepFocus then self.focusNext = true end
        end
        self:refresh()
        ghost(self, minX, minY, maxX)
    end
    return minX, minY, maxX, maxY
end

---Shows the box and puts the cursor in it. With `line`, starts a fresh line holding it
---(the "/" key passes "/", like EverQuest's chat box).
---@param line? string
function M:focus(line)
    self.open = true
    self.focusNext = true
    if line and not self.active then  -- never wipe a line you are typing
        self.text, self.cursor, self.prevCursor = line, #line, #line
        self.hist, self.histText = nil, nil
        self.pendingEdit = { text = line, cursor = #line }
    end
end

return M
