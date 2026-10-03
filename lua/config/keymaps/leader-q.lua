--[[
<leader>q: problems and lists.
]]
local M = {}

function M.setup(map, opts)
    map('n', '<leader>qq', function()
        Snacks.picker.diagnostics()
    end, opts('Workspace diagnostics'))
    map('n', '<leader>qb', function()
        Snacks.picker.diagnostics_buffer()
    end, opts('Buffer diagnostics'))
    map('n', '<leader>qs', function()
        Snacks.picker.lsp_symbols()
    end, opts('Symbols in this file'))
    map('n', '<leader>ql', function()
        Snacks.picker.lsp_workspace_symbols()
    end, opts('Symbols in the workspace'))
    map('n', '<leader>qf', function()
        Snacks.picker.qflist()
    end, opts('Quickfix list'))
    map('n', '<leader>qL', function()
        Snacks.picker.loclist()
    end, opts('Location list'))
    map('n', '<leader>qt', function()
        vim.cmd('TodoQuickFix')
        Snacks.picker.qflist({ title = 'TODO comments' })
    end, opts('TODO comments'))
end

return M