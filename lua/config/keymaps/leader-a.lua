--[[
<leader>a: whole buffer actions.
]]
local M = {}

function M.setup(map, opts)
    -- Select/copy/cut whole buffer
    map('n', '<leader>aa', 'ggVG', opts('Select the whole buffer'))
    map('n', '<leader>ay', '<cmd>%yank +<cr>', opts('Copy the whole buffer'))
    map('n', '<leader>ax', '<cmd>%delete +<cr>', opts('Cut the whole buffer'))
end

return M