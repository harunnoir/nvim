local api = vim.api
local languages = require('config.languages')

local M = {}
local configured = false
local enabled_servers = {}

local servers = {
    basedpyright = {
        command = 'basedpyright-langserver',
        config = {
            cmd = { 'basedpyright-langserver', '--stdio' },
            filetypes = { 'python' },
            root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', '.git' },
            settings = {
                basedpyright = {
                    analysis = {
                        autoImportCompletions = true,
                        diagnosticMode = 'openFilesOnly',
                        typeCheckingMode = 'standard',
                    },
                },
            },
        },
    },
    ruff = {
        command = 'ruff',
        config = {
            cmd = { 'ruff', 'server' },
            filetypes = { 'python' },
            root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
        },
    },
    clangd = {
        command = 'clangd',
        config = {
            cmd = {
                'clangd',
                '--background-index',
                '--clang-tidy',
                '--completion-style=detailed',
                '--header-insertion=iwyu',
            },
            filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
            root_markers = {
                '.clangd',
                'compile_commands.json',
                'compile_flags.txt',
                'CMakeLists.txt',
                'Makefile',
                '.git',
            },
        },
    },
    gopls = {
        command = 'gopls',
        config = {
            cmd = { 'gopls' },
            filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
            root_markers = { 'go.work', 'go.mod', '.git' },
            settings = {
                gopls = {
                    analyses = { nilness = true, unusedparams = true, unusedwrite = true },
                    completeUnimported = true,
                    gofumpt = true,
                    staticcheck = true,
                    usePlaceholders = true,
                },
            },
        },
    },
    rust_analyzer = {
        command = 'rust-analyzer',
        config = {
            cmd = { 'rust-analyzer' },
            filetypes = { 'rust' },
            root_markers = { 'Cargo.toml', 'rust-project.json', '.git' },
            settings = {
                ['rust-analyzer'] = {
                    cargo = { allFeatures = true },
                    check = { command = 'clippy' },
                    inlayHints = { bindingModeHints = { enable = true } },
                },
            },
        },
    },
    lua_ls = {
        command = 'lua-language-server',
        config = {
            cmd = { 'lua-language-server' },
            filetypes = { 'lua' },
            root_markers = { '.luarc.json', '.luarc.jsonc', '.stylua.toml', 'selene.toml', '.git' },
            settings = {
                Lua = {
                    completion = { callSnippet = 'Replace' },
                    diagnostics = { globals = { 'vim' } },
                    hint = { enable = true },
                    workspace = { checkThirdParty = false },
                },
            },
        },
    },
    bashls = {
        command = 'bash-language-server',
        config = { cmd = { 'bash-language-server', 'start' }, filetypes = { 'bash', 'sh' } },
    },
    yamlls = {
        command = 'yaml-language-server',
        config = {
            cmd = { 'yaml-language-server', '--stdio' },
            filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab' },
            settings = { yaml = { keyOrdering = false } },
        },
    },
    marksman = {
        command = 'marksman',
        config = {
            cmd = { 'marksman', 'server' },
            filetypes = { 'markdown', 'markdown.mdx' },
            root_markers = { '.marksman.toml', '.git' },
        },
    },
    ts_ls = {
        command = 'typescript-language-server',
        config = {
            cmd = { 'typescript-language-server', '--stdio' },
            filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
            root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
        },
    },
    eslint = {
        command = 'vscode-eslint-language-server',
        config = {
            cmd = { 'vscode-eslint-language-server', '--stdio' },
            filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue', 'svelte' },
            root_markers = {
                'eslint.config.js',
                'eslint.config.mjs',
                '.eslintrc',
                '.eslintrc.json',
                'package.json',
                '.git',
            },
        },
    },
    html = {
        command = 'vscode-html-language-server',
        config = { cmd = { 'vscode-html-language-server', '--stdio' }, filetypes = { 'html', 'templ' } },
    },
    cssls = {
        command = 'vscode-css-language-server',
        config = { cmd = { 'vscode-css-language-server', '--stdio' }, filetypes = { 'css', 'scss', 'less' } },
    },
    jsonls = {
        command = 'vscode-json-language-server',
        config = { cmd = { 'vscode-json-language-server', '--stdio' }, filetypes = { 'json', 'jsonc' } },
    },
}

local function names(value)
    if type(value) == 'string' then
        return { value }
    end
    return type(value) == 'table' and value or {}
end

local function requested_servers()
    local requested = {}
    for _, language in pairs(languages) do
        if type(language) == 'table' and language.enabled then
            for _, name in ipairs(names(language.lsp)) do
                requested[name] = true
            end
        end
    end
    return requested
end

function M.setup()
    if configured then
        return
    end
    configured = true

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local ok, blink = pcall(require, 'blink.cmp')
    if ok then
        capabilities = blink.get_lsp_capabilities(capabilities)
    end
    vim.lsp.config('*', { capabilities = capabilities, root_markers = { '.git' } })

    for name in pairs(requested_servers()) do
        local server = servers[name]
        if server and vim.fn.executable(server.command) == 1 then
            vim.lsp.config(name, server.config)
            vim.lsp.enable(name)
            enabled_servers[#enabled_servers + 1] = name
        end
    end

    api.nvim_create_autocmd('LspAttach', {
        group = api.nvim_create_augroup('enough_lsp_attach', { clear = true }),
        callback = function(event)
            if vim.b[event.buf].lsp_enabled == false or vim.b[event.buf].learning_mode == true then
                vim.schedule(function()
                    if api.nvim_buf_is_valid(event.buf) then
                        pcall(vim.lsp.buf_detach_client, event.buf, event.data.client_id)
                    end
                end)
                return
            end
            require('config.keymaps').lsp(event.buf)
        end,
    })
end

function M.detach(bufnr)
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        pcall(vim.lsp.buf_detach_client, bufnr, client.id)
    end
end

function M.reattach(bufnr)
    if not api.nvim_buf_is_valid(bufnr) or vim.b[bufnr].lsp_enabled == false then
        return
    end
    -- Replaying FileType asks Neovim's built-in LSP auto-activation to re-evaluate this buffer.
    vim.schedule(function()
        if api.nvim_buf_is_valid(bufnr) and vim.b[bufnr].lsp_enabled ~= false then
            api.nvim_exec_autocmds('FileType', { buffer = bufnr, modeline = false })
        end
    end)
end

function M.enabled_servers()
    return vim.deepcopy(enabled_servers)
end

return M
