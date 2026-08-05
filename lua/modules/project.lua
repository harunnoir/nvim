return {
    {
        'folke/snacks.nvim',
        lazy = false,
        opts = {
            picker = { enabled = true },
        },
    },
    {
        'stevearc/overseer.nvim',
        cmd = { 'OverseerRun', 'OverseerToggle', 'OverseerRunCmd', 'OverseerTaskAction' },
        opts = { task_list = { direction = 'bottom' } },
    },
    {
        'folke/persistence.nvim',
        event = 'BufReadPre',
        opts = {},
    },
}
