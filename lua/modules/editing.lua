return {
    {
        'nvim-mini/mini.nvim',
        lazy = false,
        config = function()
            require('mini.ai').setup({ n_lines = 300 })
            require('mini.pairs').setup()
            -- Keep Flash on `s`; use the familiar vim-surround-style keys instead.
            require('mini.surround').setup({
                mappings = {
                    add = 'ys',
                    delete = 'ds',
                    find = 'gsf',
                    find_left = 'gsF',
                    highlight = 'gsh',
                    replace = 'cs',
                    suffix_last = 'l',
                    suffix_next = 'n',
                },
                search_method = 'cover_or_next',
            })

            local icons = require('mini.icons')
            icons.setup({ style = 'glyph' })
            icons.mock_nvim_web_devicons()
            icons.tweak_lsp_kind()

            local clue = require('mini.clue')
            local clues = require('config.keymaps').clues()
            vim.list_extend(clues, {
                clue.gen_clues.g(),
                clue.gen_clues.z(),
                clue.gen_clues.marks(),
                clue.gen_clues.registers(),
                clue.gen_clues.windows(),
            })
            clue.setup({
                triggers = {
                    { mode = 'n', keys = '<Leader>' },
                    { mode = 'x', keys = '<Leader>' },
                    { mode = 'n', keys = 'g' },
                    { mode = 'n', keys = 'z' },
                    { mode = 'n', keys = '[' },
                    { mode = 'n', keys = ']' },
                },
                clues = clues,
                window = { delay = 250 },
            })

            local hipatterns = require('mini.hipatterns')
            hipatterns.setup({
                highlighters = { hex_color = hipatterns.gen_highlighter.hex_color() },
            })
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main',
        lazy = false,
        build = ':TSUpdate',
        init = function()
            vim.opt.foldmethod = 'expr'
            vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.opt.foldlevel = 99
            vim.opt.foldlevelstart = 99
            vim.opt.foldenable = true
        end,
        config = function()
            vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup('enough_treesitter', { clear = true }),
                callback = function(args)
                    pcall(vim.treesitter.start, args.buf)
                end,
            })
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        opts = {
            select = { lookahead = true },
            move = { set_jumps = true },
        },
    },
    {
        'MeanderingProgrammer/render-markdown.nvim',
        ft = 'markdown',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
        opts = {
            heading = { position = 'overlay', width = 'block' },
            code = { border = 'hide', width = 'full', left_pad = 1 },
        },
    },
}
