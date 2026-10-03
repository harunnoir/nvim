--[[
Editing: pairing, surrounds, comments, folding, indentation, undo history.

Most of this is `mini.nvim`, which is one plugin with many independent
sub-modules. It loads eagerly because several of its modules claim keys that
Neovim would otherwise take: Flash wants `s`, so Mini Surround moves to the
vim-surround style `ys`/`ds`/`cs`.
]]
return {
    {
        'nvim-mini/mini.nvim',
        lazy = false,
        config = function()
            -- `n_lines` extends text objects across many more lines than the
            -- default, which matters for long Python functions.
            require('mini.ai').setup({ n_lines = 300 })
            require('mini.pairs').setup()

            -- Flash owns `s` and `S`, so surround uses vim-surround keys
            -- instead: ys to add, ds to delete, cs to replace.
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

            -- File and LSP-kind glyphs, derived from the active colorscheme and
            -- the filetype rather than maintained by hand. See
            -- `config/icons.lua` for what this config owns itself.
            local icons = require('mini.icons')
            icons.setup({ style = 'glyph' })
            icons.mock_nvim_web_devicons()
            icons.tweak_lsp_kind()

            -- A plain key guide: pause after `<leader>` and it shows only the
            -- keys that are still available. Group names come from
            -- `config/keymaps.lua` so they cannot disagree with the mappings.
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

            -- Highlights `#RRGGBB` and similar literals where they appear.
            local hipatterns = require('mini.hipatterns')
            hipatterns.setup({
                highlighters = { hex_color = hipatterns.gen_highlighter.hex_color() },
            })

            -- Movement: `Alt+hjkl` moves the visual selection, while `]e`/`[e`
            -- keep moving whole lines. The line_ keys are cleared so
            -- `Alt+hjkl` never moves a line by accident.
            require('mini.move').setup({
                mappings = {
                    left = '<M-h>',
                    right = '<M-l>',
                    down = '<M-j>',
                    up = '<M-k>',
                    line_left = '',
                    line_right = '',
                    line_down = '',
                    line_up = '',
                },
            })

            -- `gS` toggles a call between one line and an expanded argument
            -- list, which is the fastest way to read a long signature.
            require('mini.splitjoin').setup()

            -- Comments: `gc`/`gb` operators, counts, text objects, dot-repeat.
            -- Eager so `gcc` isn't shadowed by Neovim's built-in.
            -- mini.comment only supports line comments; Comment.nvim provides both.
            require('mini.comment').setup()
            require('Comment').setup()
        end,
    },

    -- =====================================================================
    -- Tree-sitter
    -- =====================================================================
    -- Eager on purpose: its official setup is startup-loaded, and the parser for
    -- a filetype has to exist before that filetype is opened to be useful.
    -- The `foldexpr` line is what makes `zz`, `zR`, and `za` work on the real
    -- syntax tree instead of an indent heuristic.
    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main',
        lazy = false,
        build = ':TSUpdate',
        init = function()
            vim.opt.foldmethod = 'expr'
            vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            -- Start fully expanded: collapsed code you did not collapse is
            -- something to fold on purpose, not something to unfold.
            vim.opt.foldlevel = 99
            vim.opt.foldlevelstart = 99
            vim.opt.foldenable = true
        end,
        config = function()
            vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup('enough_treesitter', { clear = true }),
                desc = 'Start the Tree-sitter parser for this filetype',
                callback = function(args)
                    pcall(vim.treesitter.start, args.buf)
                end,
            })
        end,
    },

    -- Text objects and motion by syntax node: `af`/`if` for a function,
    -- `ac`/`ic` for a class, `]f`/`[f` to hop between functions.
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        opts = {
            -- `lookahead` lets a target be found slightly past the cursor, which
            -- is what makes `if` work when you are on the closing brace.
            select = { lookahead = true },
            -- Leave a jump mark behind, so `''` returns you to where you were.
            move = { set_jumps = true },
        },
    },

    -- Renders markdown in the buffer: headings as overlays, fenced code with a
    -- border. Only for markdown buffers, so it costs nothing elsewhere.
    {
        'MeanderingProgrammer/render-markdown.nvim',
        ft = 'markdown',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
        opts = {
            heading = { position = 'overlay', width = 'block' },
            code = { border = 'hide', width = 'full', left_pad = 1 },
        },
    },

    -- `gc`/`gb` for line and block comments, with counts, text objects, and
    -- `.` repeat. mini.comment only does line comments.
    {
        'numToStr/Comment.nvim',
        lazy = false,
        config = function()
            require('Comment').setup()
        end,
    },
}
