--[[
<leader>f: find and files.
]]
local M = {}

function M.setup(map, opts)
    map('n', '<leader>ff', function()
        Snacks.picker.files()
    end, opts('Find files'))
    map('n', '<leader>fg', function()
        Snacks.picker.grep()
    end, opts('Grep the project'))
    map({ 'n', 'x' }, '<leader>fw', function()
        Snacks.picker.grep_word()
    end, opts('Grep the word under the cursor'))
    map('n', '<leader>fr', function()
        Snacks.picker.recent()
    end, opts('Recent files'))
    map('n', '<leader>fh', function()
        Snacks.picker.help()
    end, opts('Help tags'))
    map('n', '<leader>fc', function()
        Snacks.picker.files({ cwd = vim.fn.stdpath('config'), title = 'Config Files' })
    end, opts('Config files'))
    map('n', '<leader>fe', '<cmd>Oil<cr>', opts('File explorer'))
    map('n', '-', '<cmd>Oil<cr>', opts('Open the parent directory'))
    map('n', '<leader>fR', '<cmd>GrugFar<cr>', opts('Find and replace'))
    map('n', ']t', function()
        require('todo-comments').jump_next()
    end, opts('Next TODO comment'))
    map('n', '[t', function()
        require('todo-comments').jump_prev()
    end, opts('Previous TODO comment'))
end

return M