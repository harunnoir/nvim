--[[
<leader>r: REPL.
Only present when a language with a REPL is enabled.
]]
local M = {}

function M.setup(map, opts)
    local langs = require('config.langs')
    if not langs.repl() then
        return
    end

    map('n', '<leader>rt', '<cmd>IronRepl<cr>', opts('Toggle the REPL'))
    map('n', '<leader>rf', '<cmd>IronFocus<cr>', opts('Focus the REPL'))
    map('n', '<leader>rh', '<cmd>IronHide<cr>', opts('Hide the REPL'))
    map('n', '<leader>rr', '<cmd>IronRestart<cr>', opts('Restart the REPL'))
    map('n', '<leader>rl', function()
        require('iron.core').send_line()
    end, opts('Send the line to the REPL'))
    map('x', '<leader>rs', function()
        require('iron.core').visual_send()
    end, opts('Send the selection to the REPL'))
    map('n', '<leader>rb', function()
        require('iron.core').send_code_block(false)
    end, opts('Send a code block'))
    map('n', '<leader>rn', function()
        require('iron.core').send_code_block(true)
    end, opts('Send a code block and move on'))
    map('n', '<leader>rp', function()
        require('iron.core').send_paragraph()
    end, opts('Send the paragraph'))
    map('n', '<leader>ra', function()
        require('iron.core').send_file()
    end, opts('Send the whole file'))
    map('n', '<leader>ru', function()
        require('iron.core').send_until_cursor()
    end, opts('Send everything up to the cursor'))
end

return M