--[[
<leader>c: code actions.
]]
local M = {}

function M.setup(map, opts, format)
    map('n', '<leader>cm', '<cmd>Mason<cr>', opts('Tool manager'))
    map('n', '<leader>cf', function()
        format(false)
    end, opts('Format the buffer'))
    map('x', '<leader>cf', function()
        format(true)
    end, opts('Format the selection'))
    map('n', '<leader>cu', function()
        Snacks.picker.colorschemes()
    end, opts('Change colorscheme'))
end

return M