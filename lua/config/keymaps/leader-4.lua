--[[
<leader>4: 42-school tools.
Only present when a language with norm is enabled.
]]
local M = {}

function M.setup(map, opts)
    local langs = require('config.langs')
    if not langs.uses('norm') then
        return
    end

    map('n', '<leader>4h', '<cmd>Stdheader<cr>', opts('Insert the 42 header'))
    map('n', '<leader>4f', '<cmd>Format42<cr>', opts('Format to 42 norm'))
    map('n', '<leader>4n', '<cmd>Check42<cr>', opts('Run Norminette'))
end

return M