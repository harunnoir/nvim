local icons = require('config.icons')
local languages = require('config.languages')
local formatters = {}
local linters = {}

local filetypes = {
    python = { 'python' },
    c = { 'c' },
    cpp = { 'cpp' },
    go = { 'go' },
    rust = { 'rust' },
    lua = { 'lua' },
    shell = { 'bash', 'sh' },
    yaml = { 'yaml' },
    markdown = { 'markdown' },
    web = {
        'css',
        'html',
        'javascript',
        'javascriptreact',
        'json',
        'jsonc',
        'typescript',
        'typescriptreact',
    },
}

for name, profile in pairs(languages) do
    if type(profile) == 'table' and profile.enabled and profile.formatters then
        for _, filetype in ipairs(filetypes[name] or {}) do
            formatters[filetype] = profile.formatters
        end
    end
    if type(profile) == 'table' and profile.enabled and profile.linters then
        for _, filetype in ipairs(filetypes[name] or {}) do
            linters[filetype] = profile.linters
        end
    end
end

return {
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
    {
        'saghen/blink.cmp',
        version = '1.*',
        lazy = false,
        dependencies = { 'rafamadriz/friendly-snippets' },
        opts = {
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
            -- Tagged releases download the prebuilt Rust matcher.
            fuzzy = { implementation = 'rust' },
            completion = {
                documentation = { auto_show = true, auto_show_delay_ms = 250 },
                ghost_text = { enabled = true },
                menu = { border = 'rounded' },
            },
            signature = { enabled = true, window = { border = 'rounded' } },
            sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
        },
    },
    {
        'stevearc/conform.nvim',
        event = 'BufWritePre',
        cmd = 'ConformInfo',
        opts = {
            default_format_opts = { lsp_format = 'fallback' },
            formatters = {
                autopep8 = { prepend_args = { '--max-line-length', '79' } },
                c_formatter_42 = {
                    command = 'c_formatter_42',
                    args = {},
                    stdin = true,
                },
                docformatter = {
                    -- Stdin avoids docformatter's in-place exit code and lets
                    -- Conform safely chain it after autopep8.
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
            format_on_save = function(bufnr)
                if vim.b[bufnr].autoformat ~= true or vim.b[bufnr].learning_mode then
                    return
                end
                return { timeout_ms = 1200, lsp_format = 'fallback' }
            end,
            formatters_by_ft = formatters,
        },
    },
    {
        'mfussenegger/nvim-lint',
        event = { 'BufReadPost', 'BufWritePost', 'InsertLeave' },
        config = function()
            local lint = require('lint')
            lint.linters_by_ft = linters

            vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave' }, {
                group = vim.api.nvim_create_augroup('enough_lint', { clear = true }),
                callback = function(args)
                    if not vim.b[args.buf].learning_mode then
                        lint.try_lint(nil, { ignore_errors = true })
                    end
                end,
            })
        end,
    },
}
