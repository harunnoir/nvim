--[[
Modes & Assistance: learning mode, minimal mode, per-buffer toggles, diagnostics.

Single module because they're tightly coupled: learning mode uses assistance toggles,
minimal mode is independent but same "editor mode" concept, diagnostics config is
the backend for warning/virtual-text toggles.
]]
local icons = require('config.icons')
local api = vim.api

local M = {}

-- =====================================================================
-- Per-buffer assistance state
-- =====================================================================
local state = {}

local features = {
    {
        name = 'diagnostics',
        key = 'd',
        is_on = function(bufnr) return vim.diagnostic.is_enabled({ bufnr = bufnr }) end,
        set = function(bufnr, on) vim.diagnostic.enable(on, { bufnr = bufnr }) end,
    },
    {
        name = 'virtual_text',
        key = 'v',
        is_on = function(bufnr) return M.get_state(bufnr).virtual_text end,
        set = function(bufnr, on)
            M.get_state(bufnr).virtual_text = on
            M.refresh_diagnostics(bufnr)
        end,
    },
    {
        name = 'warnings',
        key = 'W',
        is_on = function(bufnr) return M.get_state(bufnr).warnings end,
        set = function(bufnr, on)
            M.get_state(bufnr).warnings = on
            M.refresh_diagnostics(bufnr)
        end,
    },
    {
        name = 'lsp',
        key = 'l',
        is_on = function(bufnr) return vim.b[bufnr].lsp_enabled ~= false end,
        set = function(bufnr, on)
            vim.b[bufnr].lsp_enabled = on
            require('config.lsp')[on and 'reattach' or 'detach'](bufnr)
        end,
    },
    {
        name = 'completion',
        key = 'c',
        is_on = function(bufnr) return vim.b[bufnr].completion ~= false end,
        set = function(bufnr, on)
            vim.b[bufnr].completion = on
            if not on then
                local ok, blink = pcall(require, 'blink.cmp')
                if ok then pcall(blink.hide) pcall(blink.hide_documentation) pcall(blink.hide_signature) end
            end
        end,
    },
    {
        name = 'autoformat',
        key = 'f',
        is_on = function(bufnr) return vim.b[bufnr].autoformat == true end,
        set = function(bufnr, on) vim.b[bufnr].autoformat = on end,
    },
    {
        name = 'inlay_hints',
        key = 'h',
        is_on = function(bufnr) return vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }) end,
        set = function(bufnr, on) pcall(vim.lsp.inlay_hint.enable, on, { bufnr = bufnr }) end,
    },
}

function M.get_state(bufnr)
    bufnr = (bufnr == nil or bufnr == 0) and api.nvim_get_current_buf() or bufnr
    if not state[bufnr] then
        -- Set defaults first to avoid circular deps in is_on
        state[bufnr] = { learning = false, warnings = true, virtual_text = true }
        for _, f in ipairs(features) do
            if f.name ~= 'warnings' and f.name ~= 'virtual_text' then
                state[bufnr][f.name] = f.is_on(bufnr)
            end
        end
    end
    return state[bufnr]
end

local function apply(bufnr, feature, on)
    feature.set(bufnr, on)
    M.get_state(bufnr)[feature.name] = on
end

function M.is_blocked_by_learning(bufnr, name)
    if not M.get_state(bufnr).learning then return false end
    vim.notify(('%s %s controlled by learning mode; turn it off first'):format(icons.warn, name), vim.log.levels.WARN)
    return true
end

function M.toggle(name, bufnr)
    bufnr = (bufnr == nil or bufnr == 0) and api.nvim_get_current_buf() or bufnr
    local feature = nil
    for _, f in ipairs(features) do if f.name == name then feature = f; break end end
    if not feature then error('unknown feature: ' .. name) end
    if M.is_blocked_by_learning(bufnr, name) then return end
    local on = not feature.is_on(bufnr)
    apply(bufnr, feature, on)
    vim.notify(('%s %s: %s'):format(on and icons.toggle_on or icons.toggle_off, name, on and 'on' or 'off'), vim.log.levels.INFO)
    vim.cmd.redrawstatus()
end

function M.toggle_option(name, label)
    local enabled = not vim.opt_local[name]:get()
    vim.opt_local[name] = enabled
    vim.notify(('%s %s: %s'):format(enabled and icons.toggle_on or icons.toggle_off, label or name, enabled and 'on' or 'off'), vim.log.levels.INFO)
    vim.cmd.redrawstatus()
end

M.features = features

-- =====================================================================
-- Diagnostics config (backend for warnings/virtual_text toggles)
-- =====================================================================
local function severity(bufnr)
    if M.get_state(bufnr).warnings then return nil end
    return vim.diagnostic.severity.ERROR
end

function M.diagnostic_severity(bufnr)
    bufnr = (bufnr == nil or bufnr == 0) and api.nvim_get_current_buf() or bufnr
    return severity(bufnr)
end

function M.refresh_diagnostics(bufnr)
    vim.diagnostic.hide(nil, bufnr)
    if vim.diagnostic.is_enabled({ bufnr = bufnr }) then vim.diagnostic.show(nil, bufnr) end
end

local function diagnostics_config()
    return {
        severity_sort = true,
        update_in_insert = false,
        float = function(_, bufnr) return { border = 'rounded', source = true, severity = severity(bufnr) } end,
        virtual_text = function(_, bufnr)
            if not M.get_state(bufnr).virtual_text then return false end
            return { spacing = 2, source = 'if_many', prefix = '●', severity = severity(bufnr) }
        end,
        signs = function(_, bufnr)
            return {
                text = { [vim.diagnostic.severity.ERROR] = icons.error, [vim.diagnostic.severity.WARN] = icons.warn, [vim.diagnostic.severity.INFO] = icons.info, [vim.diagnostic.severity.HINT] = icons.hint },
                severity = severity(bufnr),
            }
        end,
        underline = function(_, bufnr) return { severity = severity(bufnr) } end,
    }
end

-- =====================================================================
-- Learning mode (snapshot/restore all assistance)
-- =====================================================================
function M.learning_enable(bufnr)
    bufnr = (bufnr == nil or bufnr == 0) and api.nvim_get_current_buf() or bufnr
    local cur = M.get_state(bufnr)
    if cur.learning then return end
    cur.before_learning = {}
    for _, f in ipairs(features) do cur.before_learning[f.name] = f.is_on(bufnr) end
    cur.learning = true
    vim.b[bufnr].learning_mode = true
    for _, f in ipairs(features) do f.set(bufnr, false); cur[f.name] = false end
    vim.notify(('%s learning mode: on'):format(icons.toggle_on), vim.log.levels.INFO)
    vim.cmd.redrawstatus()
end

function M.learning_disable(bufnr)
    bufnr = (bufnr == nil or bufnr == 0) and api.nvim_get_current_buf() or bufnr
    local cur = M.get_state(bufnr)
    if not cur.learning then return end
    cur.learning = false
    vim.b[bufnr].learning_mode = false
    for _, f in ipairs(features) do
        local on = cur.before_learning[f.name] == true
        f.set(bufnr, on); cur[f.name] = on
    end
    cur.before_learning = nil
    vim.notify(('%s learning mode: off'):format(icons.toggle_off), vim.log.levels.INFO)
    vim.cmd.redrawstatus()
end

function M.learning_toggle(bufnr)
    bufnr = (bufnr == nil or bufnr == 0) and api.nvim_get_current_buf() or bufnr
    if M.get_state(bufnr).learning then M.learning_disable(bufnr) else M.learning_enable(bufnr) end
end

function M.is_learning(bufnr)
    return M.get_state(bufnr).learning
end

-- =====================================================================
-- Minimal mode (hide UI, keep features)
-- =====================================================================
local minimal = { enabled = false, globals = {}, windows = {} }
local min_global = { cmdheight = 0, laststatus = 0, ruler = false, showcmd = false, showtabline = 0 }
local min_win = { colorcolumn = '', cursorcolumn = false, cursorline = false, foldcolumn = '0', list = false, number = false, relativenumber = false, signcolumn = 'no', statuscolumn = '', winbar = '' }

local function read_win(winid)
    local o = {}
    for n in pairs(min_win) do o[n] = api.nvim_get_option_value(n, { scope = 'local', win = winid }) end
    return o
end

local function set_win(winid, n, v) api.nvim_set_option_value(n, v, { scope = 'local', win = winid }) end

local function apply_min(winid, capture)
    if not api.nvim_win_is_valid(winid) then return end
    if not minimal.windows[winid] then minimal.windows[winid] = capture and read_win(winid) or vim.deepcopy(minimal.default_win) end
    for n, v in pairs(min_win) do set_win(winid, n, v) end
end

function M.minimal_enable()
    if minimal.enabled then return end
    minimal.globals = {}
    for n, v in pairs(min_global) do minimal.globals[n] = vim.o[n]; vim.o[n] = v end
    minimal.default_win = read_win(api.nvim_get_current_win())
    for _, w in ipairs(api.nvim_list_wins()) do apply_min(w, true) end
    minimal.enabled = true
    vim.notify(('%s minimal mode: on'):format(icons.toggle_on), vim.log.levels.INFO)
    vim.cmd.redrawstatus()
end

function M.minimal_disable()
    if not minimal.enabled then return end
    minimal.enabled = false
    for n, v in pairs(minimal.globals or {}) do vim.o[n] = v end
    for w, o in pairs(minimal.windows) do if api.nvim_win_is_valid(w) then for n, v in pairs(o) do set_win(w, n, v) end end end
    minimal.globals, minimal.default_win, minimal.windows = nil, nil, {}
    vim.notify(('%s minimal mode: off'):format(icons.toggle_off), vim.log.levels.INFO)
    vim.cmd.redrawstatus()
end

function M.minimal_toggle() if minimal.enabled then M.minimal_disable() else M.minimal_enable() end end
function M.is_minimal() return minimal.enabled end

-- =====================================================================
-- Setup
-- =====================================================================
function M.setup()
    vim.diagnostic.config(diagnostics_config())

    api.nvim_create_autocmd('BufWipeout', { group = api.nvim_create_augroup('enough_modes_cleanup', { clear = true }), callback = function(a) state[a.buf] = nil end })

    api.nvim_create_autocmd({ 'WinNew', 'BufWinEnter', 'FileType', 'TermOpen' }, { group = api.nvim_create_augroup('enough_minimal_mode', { clear = true }), callback = function() if minimal.enabled then apply_min(api.nvim_get_current_win(), false) end end })
    api.nvim_create_autocmd('WinClosed', { group = 'enough_minimal_mode', callback = function(a) minimal.windows[tonumber(a.match)] = nil end })

    -- Commands
    api.nvim_create_user_command('ModeLearn', M.learning_enable, { desc = 'Enter learning mode' })
    api.nvim_create_user_command('ModeLearnOff', M.learning_disable, { desc = 'Exit learning mode' })
    api.nvim_create_user_command('ModeLearnToggle', M.learning_toggle, { desc = 'Toggle learning mode' })
    api.nvim_create_user_command('ModeMinimal', M.minimal_enable, { desc = 'Enter minimal mode' })
    api.nvim_create_user_command('ModeNormal', M.minimal_disable, { desc = 'Restore normal interface' })
    api.nvim_create_user_command('ModeToggle', M.minimal_toggle, { desc = 'Toggle minimal mode' })
end

return M