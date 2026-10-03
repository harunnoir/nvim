--[[
Buffer-local mappings, installed by the plugin that owns the buffer.
Called from plugin on_attach callbacks.
]]
local M = {}

local map = vim.keymap.set

local function opts(desc, extra)
    return vim.tbl_extend('force', { silent = true, desc = desc }, extra or {})
end

---Read-only panes close with q.
function M.close_with_q(bufnr)
    map('n', 'q', '<cmd>close<cr>', opts('Close window', { buffer = bufnr }))
end

---In the REPL, Ctrl-\ hides it.
function M.repl(bufnr)
    map({ 'n', 't' }, '<C-\\>', '<cmd>IronHide<cr>', opts('Hide the REPL', { buffer = bufnr }))
end

---LSP actions once a server has attached.
function M.lsp(bufnr)
    local buffer = { buffer = bufnr }
    map('n', 'gd', vim.lsp.buf.definition, opts('Go to definition', buffer))
    map('n', 'gD', vim.lsp.buf.declaration, opts('Go to declaration', buffer))
    map({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, opts('Code action', buffer))
    map('n', '<leader>cr', vim.lsp.buf.rename, opts('Rename symbol', buffer))
    map('n', '<leader>cd', vim.diagnostic.open_float, opts('Diagnostics on this line', buffer))
    map('n', '<leader>ck', vim.lsp.buf.signature_help, opts('Signature help', buffer))
    map('n', '<leader>cc', vim.lsp.codelens.run, opts('Run the code lens', buffer))
    map('n', '<leader>cC', vim.lsp.codelens.refresh, opts('Refresh the code lens', buffer))
    map('n', '<leader>cs', function()
        Snacks.picker.lsp_symbols()
    end, opts('Symbols in this file', buffer))
    map('n', '<leader>cS', function()
        Snacks.picker.lsp_workspace_symbols()
    end, opts('Symbols in the workspace', buffer))
end

---Gitsigns hunk actions.
function M.gitsigns(bufnr)
    local gitsigns = require('gitsigns')
    local buffer = { buffer = bufnr }
    map('n', ']h', function()
        if vim.wo.diff then
            vim.cmd.normal({ args = { ']c' }, bang = true })
        else
            gitsigns.nav_hunk('next')
        end
    end, opts('Next hunk', buffer))
    map('n', '[h', function()
        if vim.wo.diff then
            vim.cmd.normal({ args = { '[c' }, bang = true })
        else
            gitsigns.nav_hunk('prev')
        end
    end, opts('Previous hunk', buffer))
    map('n', '<leader>gh', gitsigns.preview_hunk, opts('Preview hunk', buffer))
    map({ 'n', 'x' }, '<leader>ga', gitsigns.stage_hunk, opts('Stage hunk', buffer))
    map({ 'n', 'x' }, '<leader>gr', gitsigns.reset_hunk, opts('Reset hunk', buffer))
    map('n', '<leader>gu', gitsigns.undo_stage_hunk, opts('Undo stage hunk', buffer))
    map('n', '<leader>gB', gitsigns.blame_line, opts('Blame line', buffer))
end

return M