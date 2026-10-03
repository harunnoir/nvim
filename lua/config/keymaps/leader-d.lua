--[[
<leader>d: debug (DAP).
Only present when a language with a debugger is enabled.
]]
local M = {}

function M.setup(map, opts)
    local langs = require('config.langs')
    if not langs.uses('debugger') then
        return
    end

    map('n', '<leader>dc', function()
        require('dap').continue()
    end, opts('Continue or start'))
    map('n', '<leader>di', function()
        require('dap').step_into()
    end, opts('Step into'))
    map('n', '<leader>do', function()
        require('dap').step_over()
    end, opts('Step over'))
    map('n', '<leader>dO', function()
        require('dap').step_out()
    end, opts('Step out'))
    map('n', '<leader>dr', function()
        require('dap').run_last()
    end, opts('Run the last configuration'))
    map('n', '<leader>dt', function()
        require('dap').terminate()
    end, opts('Terminate'))
    map('n', '<leader>db', function()
        require('dap').toggle_breakpoint()
    end, opts('Toggle breakpoint'))
    map('n', '<leader>dB', function()
        require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
    end, opts('Conditional breakpoint'))
    map('n', '<leader>du', function()
        require('dapui').toggle()
    end, opts('Toggle the debug UI'))
    map({ 'n', 'x' }, '<leader>de', function()
        require('dapui').eval()
    end, opts('Evaluate under the cursor'))
end

return M