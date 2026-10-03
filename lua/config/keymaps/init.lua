--[[
Keymap registry.

Every user-facing mapping lives here. Buffer-local mappings (LSP, gitsigns, REPL)
are in buffer.lua and installed by the plugin that owns the buffer.

Sections are separate modules under this directory, loaded by setup().
]]
local M = {}

local map = vim.keymap.set

---Keymaps that are not coding assistance still need a description.
local function opts(desc, extra)
    return vim.tbl_extend('force', { silent = true, desc = desc }, extra or {})
end

---Format buffer or range (Visual mode).
local function format(range)
    local options = { async = true, lsp_format = 'fallback' }
    if range then
        local first = vim.api.nvim_buf_get_mark(0, '<')
        local last = vim.api.nvim_buf_get_mark(0, '>')
        options.range = {
            start = { first[1], first[2] },
            ['end'] = { last[1], last[2] },
        }
    end
    require('conform').format(options)
end

---Close every listed buffer except current.
local function close_other_buffers()
    local current = vim.api.nvim_get_current_buf()
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if buffer ~= current and vim.api.nvim_buf_is_loaded(buffer) and vim.bo[buffer].buflisted then
            pcall(vim.api.nvim_buf_delete, buffer, {})
        end
    end
end

---Split resizing helper.
local function resize(command)
    return function()
        vim.cmd(command)
    end
end

---Load all keymap sections.
function M.setup()
    vim.api.nvim_create_user_command('KeymapManual', M.manual, { desc = 'Search the active keymaps' })

    -- Core modules (no leader prefix)
    require('config.keymaps.general').setup(map, opts, format, close_other_buffers, resize)

    -- Leader-prefixed sections
    require('config.keymaps.leader-a').setup(map, opts)
    require('config.keymaps.leader-b').setup(map, opts)
    require('config.keymaps.leader-c').setup(map, opts, format)
    require('config.keymaps.leader-d').setup(map, opts)
    require('config.keymaps.leader-f').setup(map, opts)
    require('config.keymaps.leader-g').setup(map, opts)
    require('config.keymaps.leader-i').setup(map, opts)
    require('config.keymaps.leader-m').setup(map, opts)
    require('config.keymaps.leader-p').setup(map, opts)
    require('config.keymaps.leader-q').setup(map, opts)
    require('config.keymaps.leader-r').setup(map, opts)
    require('config.keymaps.leader-t').setup(map, opts)
    require('config.keymaps.leader-w').setup(map, opts, resize)
    require('config.keymaps.leader-x').setup(map, opts)
    require('config.keymaps.leader-4').setup(map, opts)

    -- Buffer-local mappings (installed by plugin on_attach)
    M.close_with_q = require('config.keymaps.buffer').close_with_q
    M.repl = require('config.keymaps.buffer').repl
    M.lsp = require('config.keymaps.buffer').lsp
    M.gitsigns = require('config.keymaps.buffer').gitsigns
end

-- =========================================================================
-- Keymap manual
-- =========================================================================

---Open a searchable list of the mappings active right now.
function M.manual()
    if Snacks and Snacks.picker and Snacks.picker.keymaps then
        Snacks.picker.keymaps({ title = 'Keymap Manual', plugs = false, confirm = 'close' })
        return
    end
    vim.notify('The keymap manual needs the Snacks UI module', vim.log.levels.WARN)
end

---Prefix hints for Mini Clue, shown while you hold <leader>.
---Group names are plain text; they come from here so they never disagree with mappings.
function M.clues()
    local langs = require('config.langs')
    local groups = {
        ['4'] = langs.uses('norm') and '42 school' or nil,
        a = 'whole buffer',
        b = 'buffers',
        c = 'code',
        d = langs.uses('debugger') and 'debug' or nil,
        f = 'find/files',
        g = 'git',
        i = 'AI',
        m = 'modes',
        p = 'project/tasks',
        q = 'problems/lists',
        r = langs.repl() and 'REPL' or nil,
        t = 'toggles',
        u = 'undo',
        w = 'windows',
        x = 'terminal',
    }

    local result = {}
    for key, description in pairs(groups) do
        if description then
            result[#result + 1] = { mode = 'n', keys = '<Leader>' .. key, desc = '+' .. description }
        end
    end
    result[#result + 1] = { mode = 'n', keys = '<Leader>i9', desc = '+99' }
    return result
end

return M