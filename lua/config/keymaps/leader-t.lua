--[[
<leader>t: assistance toggles.
Each feature in modes.features gets its own <leader>t<key> mapping.
]]
local M = {}

function M.setup(map, opts)
    local modes = require('config.modes')

    for _, feature in ipairs(modes.features) do
        map('n', '<leader>t' .. feature.key, function()
            modes.toggle(feature.name)
        end, opts('Toggle ' .. feature.name))
    end

    map('n', '<leader>tw', function()
        modes.toggle_option('wrap', 'line wrapping')
    end, opts('Toggle wrap'))
    map('n', '<leader>ts', function()
        modes.toggle_option('spell', 'spelling')
    end, opts('Toggle spell'))
    map('n', '<leader>tn', function()
        modes.toggle_option('relativenumber', 'relative numbers')
    end, opts('Toggle relative numbers'))

    map('n', '<leader>tm', modes.learning_toggle, opts('Toggle learning mode'))
end

return M