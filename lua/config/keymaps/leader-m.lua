--[[
<leader>m: editor modes (minimal/learning).
]]
local M = {}

function M.setup(map, opts)
    local modes = require('config.modes')

    map('n', '<leader>mm', modes.minimal_enable, opts('Enter minimal mode'))
    map('n', '<leader>mn', modes.minimal_disable, opts('Enter normal mode'))
    map('n', '<leader>mt', modes.minimal_toggle, opts('Toggle minimal mode'))
    map('n', '<leader>ml', modes.learning_toggle, opts('Toggle learning mode'))
end

return M