local icons = require('config.icons')
local languages = require('config.languages')
local formatters = {}

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
            format_on_save = function(bufnr)
                if vim.b[bufnr].autoformat == false or vim.b[bufnr].learning_mode then
                    return
                end
                return { timeout_ms = 1200, lsp_format = 'fallback' }
            end,
            formatters_by_ft = formatters,
        },
    },
}
