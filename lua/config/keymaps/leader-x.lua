--[[
<leader>x: terminal workflow.
]]
local M = {}

function M.setup(map, opts)
    -- Ctrl-\ and <leader>xt both restore last terminal
    map({ 'n', 't' }, '<C-\\>', '<cmd>TerminalToggle<cr>', opts('Toggle the last terminal'))
    map('n', '<leader>xt', '<cmd>TerminalToggle<cr>', opts('Toggle the last terminal'))
    map('n', '<leader>xf', '<cmd>TerminalFloat<cr>', opts('Floating terminal'))
    map('n', '<leader>xh', '<cmd>TerminalHorizontal<cr>', opts('Horizontal terminal'))
    map('n', '<leader>xv', '<cmd>TerminalVertical<cr>', opts('Vertical terminal'))
    map('n', '<leader>xd', '<cmd>TerminalDirectory<cr>', opts('Terminal in the file directory'))
    map('n', '<leader>xp', '<cmd>TerminalProject<cr>', opts('Terminal at the project root'))
    map('n', '<leader>xn', '<cmd>TerminalNew<cr>', opts('New named terminal'))
    map('n', '<leader>xl', '<cmd>TerminalSelect<cr>', opts('Select a terminal'))
    map('n', '<leader>xr', '<cmd>TerminalRestart<cr>', opts('Restart a terminal'))
    map('n', '<leader>xq', '<cmd>TerminalStop<cr>', opts('Stop a terminal'))
end

return M