--[[
Compatibility layer for config.toggles -> config.modes

Kept for tests and any external code. Use config.modes directly in new code.
]]
local modes = require('config.modes')

local M = {}

M.features = modes.features
M.toggle = modes.toggle
M.toggle_option = modes.toggle_option
M.toggle_learning = modes.learning_toggle
M.is_learning = modes.is_learning
M.minimal = modes.minimal_enable
M.normal = modes.minimal_disable
M.toggle_minimal = modes.minimal_toggle
M.is_minimal = modes.is_minimal
M.diagnostic_severity = modes.diagnostic_severity

function M.setup()
    modes.setup()
end

return M