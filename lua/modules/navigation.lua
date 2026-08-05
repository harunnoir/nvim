local icons = require('config.icons')
local columns = require('modules').editing
    and { 'icon', 'permissions', 'size', 'mtime' }
    or { 'permissions', 'size', 'mtime' }

return {
    {
        'folke/snacks.nvim',
        lazy = false,
        opts = {
            bufdelete = { enabled = true },
            picker = {
                enabled = true,
                ui_select = true,
                layout = { preset = 'ivy', cycle = true },
            },
        },
    },
    {
        'stevearc/oil.nvim',
        lazy = false,
        opts = {
            default_file_explorer = true,
            delete_to_trash = vim.fn.executable('trash-put') == 1,
            skip_confirm_for_simple_edits = false,
            columns = columns,
            view_options = { show_hidden = false, natural_order = true },
            float = { border = 'rounded', max_width = 100, max_height = 35 },
        },
    },
    {
        'folke/flash.nvim',
        event = 'VeryLazy',
        opts = {},
    },
    {
        'folke/todo-comments.nvim',
        version = '*',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {
            -- Keep project notes visible without adding another permanent panel.
            signs = true,
            keywords = {
                FIX = { icon = icons.bug .. ' ' },
                TODO = { icon = icons.todo .. ' ' },
                HACK = { icon = icons.hack .. ' ' },
                WARN = { icon = icons.warn .. ' ' },
                PERF = { icon = icons.perf .. ' ' },
                NOTE = { icon = icons.note .. ' ' },
                TEST = { icon = icons.test .. ' ' },
            },
            highlight = {
                comments_only = true,
                keyword = 'wide',
                after = 'fg',
            },
        },
    },
    {
        'folke/trouble.nvim',
        cmd = 'Trouble',
        opts = {},
    },
    {
        'MagicDuck/grug-far.nvim',
        cmd = 'GrugFar',
        opts = {},
    },
}
