-- Language tools live here so LSP, formatting, debugging, REPLs, and health
-- checks all read the same names. Set only `enabled` when switching a language.
local M = {
    python = {
        enabled = true,
        lsp = {
            'basedpyright',
            -- 'ruff', -- Flake8 owns Python lint diagnostics.
        },
        linters = { 'flake8' },
        formatters = { 'autopep8', 'docformatter' },
        debugger = 'debugpy',
        repl = { 'ptipython', 'ipython', 'ptpython', 'python' },
    },

    c = {
        enabled = true,
        lsp = 'clangd',
        formatters = { 'c_formatter_42' },
        debugger = 'codelldb',
    },

    cpp = {
        enabled = true,
        lsp = 'clangd',
        formatters = { 'c_formatter_42' },
        debugger = 'codelldb',
    },

    go = {
        enabled = false,
        lsp = 'gopls',
        formatters = { 'gofumpt', 'goimports' },
        debugger = 'delve',
    },

    rust = {
        enabled = false,
        lsp = 'rust_analyzer',
        formatters = { 'rustfmt' },
        debugger = 'codelldb',
    },

    lua = {
        enabled = false,
        lsp = 'lua_ls',
        formatters = { 'stylua' },
    },

    shell = {
        enabled = false,
        lsp = 'bashls',
        formatters = { 'shfmt' },
    },

    yaml = {
        enabled = false,
        lsp = 'yamlls',
        formatters = { 'prettier' },
    },

    markdown = {
        enabled = false,
        lsp = 'marksman',
        formatters = { 'prettier' },
    },

    web = {
        enabled = false,
        lsp = { 'ts_ls', 'eslint', 'html', 'cssls', 'jsonls' },
        formatters = { 'prettier' },
    },
}

-- Example: nvim --cmd "lua vim.g.enough_languages={go=true}"
for name, value in pairs(vim.g.enough_languages or {}) do
    assert(type(M[name]) == 'table', 'unknown language override: ' .. name)
    assert(type(value) == 'boolean', 'language overrides must be boolean: ' .. name)
    M[name].enabled = value
end

return M
