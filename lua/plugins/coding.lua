--[[
Coding assistance: tools, completion, formatting, linting, and the small
readers that make editing code bearable.

The formatter and linter lists are not written here. They come from
`config/langs.lua`, so a language profile is the only place that decides which
tools a filetype uses.
]]
local icons = require('config.icons')
local langs = require('config.langs')

return {
    -- =====================================================================
    -- Mason
    -- =====================================================================
    -- Eager and high priority because it owns the `PATH` entry that makes every
    -- other tool findable. `PATH = 'prepend'` puts `mason/bin` first.
    {
        'mason-org/mason.nvim',
        lazy = false,
        priority = 900,
        opts = {
            PATH = 'prepend',
            max_concurrent_installers = 2,
            ui = {
                border = 'rounded',
                icons = {
                    package_installed = icons.success,
                    package_pending = icons.pending,
                    package_uninstalled = icons.error,
                },
            },
        },
    },

    -- =====================================================================
    -- Completion
    -- =====================================================================
    -- Eager, and this is the one lazy-loading exception worth explaining: the
    -- LSP client capabilities have to be sent when a server is configured, not
    -- when completion first runs, so Blink must exist during startup.
    --
    -- The Rust matcher matters. The pure-Lua fallback is noticeably slower on a
    -- large project, and `bin/install.sh` downloads the prebuilt library for
    -- tagged releases, compiling it only if that download failed.
    {
        'saghen/blink.cmp',
        version = '1.*',
        lazy = false,
        dependencies = { 'rafamadriz/friendly-snippets' },
        opts = {
            -- One place that decides whether completion may run, so the
            -- `<leader>tc` toggle, learning mode, and the real thing agree.
            enabled = function()
                return vim.bo.buftype ~= 'prompt'
                    and vim.b.completion ~= false
                    and vim.b.learning_mode ~= true
            end,
            keymap = {
                preset = 'default',
                ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
                ['<C-e>'] = { 'hide' },
            },
            appearance = { nerd_font_variant = 'mono' },
            fuzzy = { implementation = 'rust' },
            completion = {
                -- Documentation appears on its own after a quarter second, so
                -- you do not have to ask for it and do not wait for every item.
                documentation = { auto_show = true, auto_show_delay_ms = 250 },
                ghost_text = { enabled = true },
                menu = { border = 'rounded' },
            },
            signature = { enabled = true, window = { border = 'rounded' } },
            -- `path` and `buffer` are what make a filename or a local variable
            -- completable without an LSP; snippets cover the rest.
            sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
        },
    },

    -- =====================================================================
    -- Formatting
    -- =====================================================================
    -- On `BufWritePre` and nothing earlier: a formatter should cost nothing
    -- until a file is actually saved.
    {
        'stevearc/conform.nvim',
        event = 'BufWritePre',
        cmd = 'ConformInfo',
        opts = {
            default_format_opts = { lsp_format = 'fallback' },
            -- Python: keep to autopep8 and let the server format, so the two
            -- never fight over the same line.
            formatters = {
                autopep8 = { prepend_args = { '--max-line-length', '79' } },
                c_formatter_42 = {
                    command = 'c_formatter_42',
                    args = {},
                    stdin = true,
                },
                docformatter = {
                    -- `-` makes docformatter read stdin. Without it it would
                    -- rewrite the file in place and exit non-zero, which breaks
                    -- chaining it after autopep8.
                    args = {
                        '--wrap-summaries',
                        '79',
                        '--wrap-descriptions',
                        '79',
                        '-',
                    },
                    stdin = true,
                },
            },
            -- Off unless asked for. Format-on-save that reformats code you did
            -- not touch is a surprise, so it starts off in every buffer.
            format_on_save = function(bufnr)
                if vim.b[bufnr].autoformat ~= true or vim.b[bufnr].learning_mode then
                    return
                end
                -- `lsp_format = 'fallback'` means a missing formatter is a no-op
                -- rather than a reflow by whichever server is attached.
                return { timeout_ms = 1200, lsp_format = 'fallback' }
            end,
            formatters_by_ft = langs.formatters_by_filetype(),
        },
    },

    -- =====================================================================
    -- LSP status
    -- =====================================================================
    -- Progress spinner while a server attaches or works. Fidget owns this, so
    -- Noice's own LSP progress is switched off in `plugins/ui.lua`.
    {
        'j-hui/fidget.nvim',
        event = 'LspAttach',
        opts = {},
    },

    -- =====================================================================
    -- Linting
    -- =====================================================================
    -- Runs on read, on write, and when you leave insert mode -- never on every
    -- keystroke, which is what makes a linter feel slow.
    {
        'mfussenegger/nvim-lint',
        event = { 'BufReadPost', 'BufWritePost', 'InsertLeave' },
        config = function()
            local lint = require('lint')
            lint.linters_by_ft = langs.linters_by_filetype()

            vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave' }, {
                group = vim.api.nvim_create_augroup('enough_lint', { clear = true }),
                desc = 'Run the linters for this filetype',
                callback = function(args)
                    if not vim.b[args.buf].learning_mode then
                        lint.try_lint(nil, { ignore_errors = true })
                    end
                end,
            })
        end,
    },
}
