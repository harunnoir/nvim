-- Buffer-local coding-assistance toggles.
-- Learning mode keeps syntax colors while disabling automatic coding help.
local M = {}
local icons = require('config.icons')
local states = {}
local minimal = {
    enabled = false,
    windows = {},
}

local minimal_global_options = {
    cmdheight = 0,
    laststatus = 0,
    ruler = false,
    showcmd = false,
    showtabline = 0,
}

local minimal_window_options = {
    colorcolumn = '',
    cursorcolumn = false,
    cursorline = false,
    foldcolumn = '0',
    list = false,
    number = false,
    relativenumber = false,
    signcolumn = 'no',
    statuscolumn = '',
    winbar = '',
}

local diagnostic_signs = {
    text = {
        [vim.diagnostic.severity.ERROR] = icons.error,
        [vim.diagnostic.severity.WARN] = icons.warn,
        [vim.diagnostic.severity.INFO] = icons.info,
        [vim.diagnostic.severity.HINT] = icons.hint,
    },
}

local function current_buffer(bufnr)
    if bufnr == nil or bufnr == 0 then
        return vim.api.nvim_get_current_buf()
    end
    return bufnr
end

local function state(bufnr)
    bufnr = current_buffer(bufnr)
    if not states[bufnr] then
        states[bufnr] = {
            diagnostics = vim.diagnostic.is_enabled({ bufnr = bufnr }),
            virtual_text = true,
            warnings = true,
            lsp = vim.b[bufnr].lsp_enabled ~= false,
            completion = vim.b[bufnr].completion ~= false,
            format_on_save = vim.b[bufnr].autoformat == true,
            inlay_hints = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
            learning = vim.b[bufnr].learning_mode == true,
        }
    end
    return states[bufnr]
end

local function notify(name, enabled, level)
    local icon = enabled and icons.toggle_on or icons.toggle_off
    vim.notify(('%s %s: %s'):format(icon, name, enabled and 'on' or 'off'), level or vim.log.levels.INFO)
    vim.cmd.redrawstatus()
end

local function window_option(winid, name)
    return vim.api.nvim_get_option_value(name, { scope = 'local', win = winid })
end

local function set_window_option(winid, name, value)
    vim.api.nvim_set_option_value(name, value, { scope = 'local', win = winid })
end

local function read_window_options(winid)
    local options = {}
    for name in pairs(minimal_window_options) do
        options[name] = window_option(winid, name)
    end
    return options
end

local function apply_minimal_window(winid, capture)
    if not vim.api.nvim_win_is_valid(winid) then return end

    if not minimal.windows[winid] then
        -- New splits inherit the hidden options. Restore them to the interface
        -- that was active when minimal mode started instead.
        minimal.windows[winid] = capture and read_window_options(winid) or vim.deepcopy(minimal.default_window)
    end

    for name, value in pairs(minimal_window_options) do
        set_window_option(winid, name, value)
    end
end

local function set_minimal(enabled)
    if minimal.enabled == enabled then return end

    if enabled then
        minimal.globals = {}
        for name, value in pairs(minimal_global_options) do
            minimal.globals[name] = vim.o[name]
            vim.o[name] = value
        end
        minimal.enabled = true
        minimal.default_window = read_window_options(vim.api.nvim_get_current_win())
        for _, winid in ipairs(vim.api.nvim_list_wins()) do
            apply_minimal_window(winid, true)
        end
    else
        minimal.enabled = false
        for name, value in pairs(minimal.globals or {}) do
            vim.o[name] = value
        end
        for winid, options in pairs(minimal.windows) do
            if vim.api.nvim_win_is_valid(winid) then
                for name, value in pairs(options) do
                    set_window_option(winid, name, value)
                end
            end
        end
        minimal.globals = nil
        minimal.default_window = nil
        minimal.windows = {}
    end

    notify('minimal mode', enabled)
end

local function blocked_by_learning(bufnr, feature)
    if not state(bufnr).learning then
        return false
    end
    vim.notify(
        ('%s %s is controlled by learning mode; turn learning mode off first'):format(icons.warn, feature),
        vim.log.levels.WARN
    )
    return true
end

local function severity_for(bufnr)
    if state(bufnr).warnings then
        return nil
    end
    return vim.diagnostic.severity.ERROR
end

local function refresh_diagnostics(bufnr)
    vim.diagnostic.hide(nil, bufnr)
    if vim.diagnostic.is_enabled({ bufnr = bufnr }) then
        vim.diagnostic.show(nil, bufnr)
    end
end

local function set_diagnostics(bufnr, enabled)
    state(bufnr).diagnostics = enabled
    vim.diagnostic.enable(enabled, { bufnr = bufnr })
end

local function set_virtual_text(bufnr, enabled)
    state(bufnr).virtual_text = enabled
    refresh_diagnostics(bufnr)
end

local function set_warnings(bufnr, enabled)
    state(bufnr).warnings = enabled
    refresh_diagnostics(bufnr)
end

local function set_completion(bufnr, enabled)
    state(bufnr).completion = enabled
    vim.b[bufnr].completion = enabled

    if not enabled then
        local ok, blink = pcall(require, 'blink.cmp')
        if ok then
            pcall(blink.hide)
            pcall(blink.hide_documentation)
            pcall(blink.hide_signature)
        end
    end
end

local function set_format(bufnr, enabled)
    state(bufnr).format_on_save = enabled
    vim.b[bufnr].autoformat = enabled
end

local function set_inlay_hints(bufnr, enabled)
    state(bufnr).inlay_hints = enabled
    pcall(vim.lsp.inlay_hint.enable, enabled, { bufnr = bufnr })
end

local function set_lsp(bufnr, enabled)
    state(bufnr).lsp = enabled
    vim.b[bufnr].lsp_enabled = enabled

    local lsp = require('config.lsp')
    if enabled then
        lsp.reattach(bufnr)
    else
        lsp.detach(bufnr)
    end
end

function M.setup()
    vim.diagnostic.config({
        severity_sort = true,
        update_in_insert = false,
        float = function(_, bufnr)
            return {
                border = 'rounded',
                source = true,
                severity = severity_for(bufnr),
            }
        end,
        virtual_text = function(_, bufnr)
            if not state(bufnr).virtual_text then
                return false
            end
            return {
                spacing = 2,
                source = 'if_many',
                prefix = '●',
                severity = severity_for(bufnr),
            }
        end,
        signs = function(_, bufnr)
            return vim.tbl_extend('force', diagnostic_signs, { severity = severity_for(bufnr) })
        end,
        underline = function(_, bufnr)
            return { severity = severity_for(bufnr) }
        end,
    })

    vim.api.nvim_create_autocmd('BufWipeout', {
        group = vim.api.nvim_create_augroup('enough_toggle_cleanup', { clear = true }),
        callback = function(args)
            states[args.buf] = nil
        end,
    })

    vim.api.nvim_create_autocmd({ 'WinNew', 'BufWinEnter', 'FileType', 'TermOpen' }, {
        group = vim.api.nvim_create_augroup('enough_minimal_mode', { clear = true }),
        callback = function()
            if minimal.enabled then
                apply_minimal_window(vim.api.nvim_get_current_win())
            end
        end,
    })

    vim.api.nvim_create_autocmd('WinClosed', {
        group = 'enough_minimal_mode',
        callback = function(args)
            minimal.windows[tonumber(args.match)] = nil
        end,
    })

    vim.api.nvim_create_user_command('ModeMinimal', function()
        set_minimal(true)
    end, { desc = 'Enter distraction-free minimal mode' })
    vim.api.nvim_create_user_command('ModeNormal', function()
        set_minimal(false)
    end, { desc = 'Restore the normal editor interface' })
    vim.api.nvim_create_user_command('ModeToggle', M.toggle_minimal, { desc = 'Toggle minimal mode' })
end

function M.minimal()
    set_minimal(true)
end

function M.normal()
    set_minimal(false)
end

function M.toggle_minimal()
    set_minimal(not minimal.enabled)
end

function M.is_minimal()
    return minimal.enabled
end

function M.toggle_option(name, label)
    local enabled = not vim.opt_local[name]:get()
    vim.opt_local[name] = enabled
    notify(label or name, enabled)
end

function M.toggle_diagnostics(bufnr)
    bufnr = current_buffer(bufnr)
    if blocked_by_learning(bufnr, 'diagnostics') then return end

    local enabled = not vim.diagnostic.is_enabled({ bufnr = bufnr })
    set_diagnostics(bufnr, enabled)
    notify('diagnostics', enabled)
end

function M.toggle_virtual_text(bufnr)
    bufnr = current_buffer(bufnr)
    if blocked_by_learning(bufnr, 'diagnostic virtual text') then return end

    local enabled = not state(bufnr).virtual_text
    set_virtual_text(bufnr, enabled)
    notify('diagnostic virtual text', enabled)
end

function M.toggle_warnings(bufnr)
    bufnr = current_buffer(bufnr)
    if blocked_by_learning(bufnr, 'warnings') then return end

    local enabled = not state(bufnr).warnings
    set_warnings(bufnr, enabled)
    notify('warnings', enabled)
end

function M.toggle_completion(bufnr)
    bufnr = current_buffer(bufnr)
    if blocked_by_learning(bufnr, 'completion') then return end

    local enabled = vim.b[bufnr].completion == false
    set_completion(bufnr, enabled)
    notify('completion', enabled)
end

function M.toggle_format(bufnr)
    bufnr = current_buffer(bufnr)
    if blocked_by_learning(bufnr, 'format on save') then return end

    local enabled = vim.b[bufnr].autoformat ~= true
    set_format(bufnr, enabled)
    notify('format on save', enabled)
end

function M.toggle_inlay_hints(bufnr)
    bufnr = current_buffer(bufnr)
    if blocked_by_learning(bufnr, 'inlay hints') then return end

    local enabled = not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
    set_inlay_hints(bufnr, enabled)
    notify('inlay hints', enabled)
end

function M.toggle_lsp(bufnr)
    bufnr = current_buffer(bufnr)
    if blocked_by_learning(bufnr, 'LSP') then return end

    local enabled = vim.b[bufnr].lsp_enabled == false
    set_lsp(bufnr, enabled)
    notify('LSP', enabled)
end

function M.toggle_learning(bufnr)
    bufnr = current_buffer(bufnr)
    local current = state(bufnr)

    if not current.learning then
        current.before_learning = {
            diagnostics = vim.diagnostic.is_enabled({ bufnr = bufnr }),
            virtual_text = current.virtual_text,
            warnings = current.warnings,
            lsp = vim.b[bufnr].lsp_enabled ~= false,
            completion = vim.b[bufnr].completion ~= false,
            format_on_save = vim.b[bufnr].autoformat == true,
            inlay_hints = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
        }

        current.learning = true
        vim.b[bufnr].learning_mode = true
        set_diagnostics(bufnr, false)
        set_virtual_text(bufnr, false)
        set_warnings(bufnr, false)
        set_completion(bufnr, false)
        set_format(bufnr, false)
        set_inlay_hints(bufnr, false)
        set_lsp(bufnr, false)
    else
        local previous = current.before_learning or {}
        current.learning = false
        vim.b[bufnr].learning_mode = false

        set_virtual_text(bufnr, previous.virtual_text ~= false)
        set_warnings(bufnr, previous.warnings ~= false)
        set_completion(bufnr, previous.completion ~= false)
        set_format(bufnr, previous.format_on_save == true)
        set_inlay_hints(bufnr, previous.inlay_hints == true)
        set_lsp(bufnr, previous.lsp ~= false)
        set_diagnostics(bufnr, previous.diagnostics ~= false)
        current.before_learning = nil
    end

    notify('learning mode', current.learning)
end

function M.diagnostic_severity(bufnr)
    return severity_for(current_buffer(bufnr))
end

function M.is_learning(bufnr)
    return state(current_buffer(bufnr)).learning
end

return M
