--[[
<leader>g: git.
]]
local M = {}

function M.setup(map, opts)
    map('n', '<leader>gg', function()
        Snacks.lazygit()
    end, opts('Lazygit'))
    map('n', '<leader>gd', '<cmd>DiffviewOpen<cr>', opts('Open the diff view'))
    map('n', '<leader>gD', '<cmd>DiffviewFileHistory %<cr>', opts('History of this file'))
    map('n', '<leader>gv', '<cmd>DiffviewClose<cr>', opts('Close the diff view'))
    map({ 'n', 'x' }, '<leader>go', function()
        Snacks.gitbrowse()
    end, opts('Open in the browser'))
    map('n', '<leader>gl', function()
        Snacks.picker.git_log()
    end, opts('Git log'))
    map('n', '<leader>gs', function()
        Snacks.picker.git_status()
    end, opts('Git status'))
    map('n', '<leader>gb', function()
        Snacks.picker.git_branches()
    end, opts('Git branches'))
end

return M