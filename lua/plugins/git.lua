--[[
Git: hunk-level work in the buffer, and a full view of history on demand.
]]
return {
    -- Signs and hunk actions in the gutter. `on_attach` installs the hunk
    -- keymaps into this buffer only, via `config/keymaps.lua`.
    {
        'lewis6991/gitsigns.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            -- Bars rather than single characters: the hunk line is what carries
            -- the meaning, and one column is cheaper to read than two symbols.
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

    -- Side-by-side diffs and per-file history. On `cmd` because it is a place
    -- you go to look, not a thing that follows you around.
    {
        'sindrets/diffview.nvim',
        cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose', 'DiffviewToggleFiles' },
    },
}
