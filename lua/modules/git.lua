return {
    {
        'lewis6991/gitsigns.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            signs = {
                add = { text = '┃' },
                change = { text = '┃' },
                delete = { text = '_' },
                topdelete = { text = '‾' },
                changedelete = { text = '~' },
                untracked = { text = '┆' },
            },
            on_attach = function(bufnr)
                require('config.keymaps').gitsigns(bufnr)
            end,
        },
    },
    {
        'folke/snacks.nvim',
        lazy = false,
        opts = {
            git = { enabled = true },
            gitbrowse = { enabled = true },
            lazygit = { enabled = true },
            picker = { enabled = true },
        },
    },
}
