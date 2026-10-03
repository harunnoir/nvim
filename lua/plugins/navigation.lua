--[[
Navigation: jumping, searching, files, and project notes.

Nothing here is a file tree or a fuzzy finder of its own; those come from Snacks
and Oil, configured in `snacks.lua` and below.
]]
local icons = require('config.icons')

return {
    -- =====================================================================
    -- Oil, the file explorer
    -- =====================================================================
    -- Eager because it replaces netrw, and `netrwPlugin` is disabled in
    -- `config/lazy.lua`. A replacement that loads late is just a gap.
    {
        'stevearc/oil.nvim',
        lazy = false,
        opts = {
            default_file_explorer = true,
            -- Moving to the trash is recoverable and deleting is not, so the
            -- distinction is only made when `trash-put` actually exists.
            delete_to_trash = vim.fn.executable('trash-put') == 1,
            -- Simple renames are still renames; skip the confirm dialog.
            skip_confirm_for_simple_edits = false,
            columns = { 'icon', 'permissions', 'size', 'mtime' },
            view_options = { show_hidden = false, natural_order = true },
            float = { border = 'rounded', max_width = 100, max_height = 35 },
        },
    },

    -- =====================================================================
    -- Flash
    -- =====================================================================
    -- `s` to jump, `S` to select by syntax node. `VeryLazy` because jumping is
    -- something you do after reading, never while starting up.
    {
        'folke/flash.nvim',
        event = 'VeryLazy',
        opts = {},
    },

    -- =====================================================================
    -- TODO comments
    -- =====================================================================
    -- Signs and highlighting make notes visible in place. Pinned to `*` because
    -- this is the one plugin here that a new keyword should reach
    -- immediately, without a lockfile update.
    {
        'folke/todo-comments.nvim',
        version = '*',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {
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
                -- Only inside comments, so a `TODO` in a string or an identifier
                -- is not suddenly important.
                comments_only = true,
                keyword = 'wide',
                after = 'fg',
            },
        },
    },

    -- =====================================================================
    -- Search and replace
    -- =====================================================================
    -- With a live preview, which `Snacks.picker.grep` does not do. It is only
    -- worth loading when you are about to replace something.
    {
        'MagicDuck/grug-far.nvim',
        cmd = 'GrugFar',
        opts = {},
    },

    -- =====================================================================
    -- Tmux navigation
    -- =====================================================================
    -- Seamless navigation between Neovim splits and tmux panes with Ctrl-h/j/k/l.
    -- Loads on VeryLazy since it's a quality-of-life feature, not startup-critical.
    {
        'christoomey/vim-tmux-navigator',
        event = 'VeryLazy',
        cmd = {
            'TmuxNavigateLeft',
            'TmuxNavigateDown',
            'TmuxNavigateUp',
            'TmuxNavigateRight',
            'TmuxNavigatePrevious',
        },
        init = function()
            vim.g.tmux_navigator_no_mappings = 1
            vim.g.tmux_navigator_preserve_zoom = 1
        end,
        keys = {
            { '<C-h>', '<cmd>TmuxNavigateLeft<cr>', desc = 'Navigate left' },
            { '<C-j>', '<cmd>TmuxNavigateDown<cr>', desc = 'Navigate down' },
            { '<C-k>', '<cmd>TmuxNavigateUp<cr>', desc = 'Navigate up' },
            { '<C-l>', '<cmd>TmuxNavigateRight<cr>', desc = 'Navigate right' },
            { '<C-\\>', '<cmd>TmuxNavigatePrevious<cr>', desc = 'Navigate previous' },
        },
    },
}
