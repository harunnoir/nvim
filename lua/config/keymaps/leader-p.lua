--[[
<leader>p: projects, tasks, sessions.
]]
local M = {}

function M.setup(map, opts)
    map('n', '<leader>pp', function()
        Snacks.picker.projects()
    end, opts('Projects'))
    map('n', '<leader>pt', '<cmd>OverseerRun<cr>', opts('Run a task'))
    map('n', '<leader>po', '<cmd>OverseerToggle<cr>', opts('Toggle the task output'))
    map('n', '<leader>pc', '<cmd>OverseerRunCmd<cr>', opts('Run a shell command'))
    map('n', '<leader>pa', '<cmd>OverseerTaskAction<cr>', opts('Task action'))
    map('n', '<leader>ps', function()
        require('persistence').load()
    end, opts('Restore a session'))
    map('n', '<leader>pS', function()
        require('persistence').select()
    end, opts('Select a session'))
    map('n', '<leader>pl', function()
        require('persistence').load({ last = true })
    end, opts('Restore the last session'))
end

return M