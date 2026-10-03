--[[
Project work: running tasks and coming back to where you were.

Both are on `cmd`, which is the point -- a task runner that runs something at
startup and a session manager that restores windows at startup would both be
doing work you did not ask for yet.
]]
return {
    -- Tasks from `.vscode/tasks.json`, or any format Overseer supports.
    {
        'stevearc/overseer.nvim',
        cmd = { 'OverseerRun', 'OverseerToggle', 'OverseerRunCmd', 'OverseerTaskAction' },
        opts = {
            -- Output at the bottom so it lands where your terminal is.
            task_list = { direction = 'bottom' },
        },
    },

    -- Per-directory sessions, stored under `stdpath('state')`. `BufReadPre` so a
    -- restored session is ready before the first file is drawn.
    {
        'folke/persistence.nvim',
        event = 'BufReadPre',
        opts = {},
    },
}
