--[[
<leader>i: AI (99) - explicit, selection-scoped.
]]
local M = {}

function M.setup(map, opts)
    map('n', '<leader>i9s', function()
        require('99').search()
    end, opts('AI project search'))
    map('v', '<leader>i9v', function()
        require('99').visual()
    end, opts('AI edit the selection'))
    map('n', '<leader>i9o', function()
        require('99').open()
    end, opts('Open the latest AI result'))
    map('n', '<leader>i9x', function()
        require('99').stop_all_requests()
    end, opts('Stop AI requests'))
    map('n', '<leader>i9m', function()
        require('99.extensions.telescope').select_model()
    end, opts('Select the AI model'))
end

return M