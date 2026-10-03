--[[
<leader>w: window management.
]]
local M = {}

function M.setup(map, opts, resize)
    -- Focus
    map('n', '<C-h>', '<C-w>h', opts('Focus left window'))
    map('n', '<C-j>', '<C-w>j', opts('Focus lower window'))
    map('n', '<C-k>', '<C-w>k', opts('Focus upper window'))
    map('n', '<C-l>', '<C-w>l', opts('Focus right window'))

    -- Resize (also works in terminal mode)
    map({ 'n', 't' }, '<A-h>', resize('vertical resize -2'), opts('Decrease window width'))
    map({ 'n', 't' }, '<A-j>', resize('resize +2'), opts('Increase window height'))
    map({ 'n', 't' }, '<A-k>', resize('resize -2'), opts('Decrease window height'))
    map({ 'n', 't' }, '<A-l>', resize('vertical resize +2'), opts('Increase window width'))

    -- Splits
    map('n', '<leader>wv', '<C-w>v', opts('Split vertically'))
    map('n', '<leader>ws', '<C-w>s', opts('Split horizontally'))
    map('n', '<leader>wc', '<C-w>c', opts('Close window'))
    map('n', '<leader>we', '<C-w>=', opts('Equalize windows'))

    -- Maximize (reversible) vs only (destructive)
    map('n', '<leader>wo', '<C-w>o', opts('Keep only this window'))
    map('n', '<leader>wm', '<cmd>Maximize<cr>', opts('Toggle window maximize'))

    -- Move windows
    map('n', '<leader>wh', '<C-w>H', opts('Move window left'))
    map('n', '<leader>wj', '<C-w>J', opts('Move window down'))
    map('n', '<leader>wk', '<C-w>K', opts('Move window up'))
    map('n', '<leader>wl', '<C-w>L', opts('Move window right'))

    -- Resize via leader (alternative to Alt)
    map('n', '<leader>wH', resize('vertical resize -2'), opts('Decrease window width'))
    map('n', '<leader>wJ', resize('resize +2'), opts('Increase window height'))
    map('n', '<leader>wK', resize('resize -2'), opts('Decrease window height'))
    map('n', '<leader>wL', resize('vertical resize +2'), opts('Increase window width'))

    -- Terminal mode navigation
    map('t', '<Esc><Esc>', '<C-\\><C-n>', opts('Leave terminal mode'))
    map('t', '<C-h>', '<C-\\><C-n><C-w>h', opts('Focus left window'))
    map('t', '<C-j>', '<C-\\><C-n><C-w>j', opts('Focus lower window'))
    map('t', '<C-k>', '<C-\\><C-n><C-w>k', opts('Focus upper window'))
    map('t', '<C-l>', '<C-\\><C-n><C-w>l', opts('Focus right window'))
end

return M