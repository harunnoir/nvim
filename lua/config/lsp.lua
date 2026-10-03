--[[
Language servers.

One entry per server, and the entry carries the binary it needs. That single
fact is why `config/health.lua` and `bin/lang/*.sh` do not keep their own list
of executables: they read `M.servers`.

A server is only enabled when its binary exists. That is what lets this config
ship the same file whether or not a given language's tooling has been installed
yet -- a missing binary degrades to "no completion for that language" instead
of an error on every keystroke.

The keys are the names used in `config/langs.lua`; the values are ordinary
`vim.lsp.config` tables. See `:help vim.lsp.config`.
]]
local api = vim.api
local langs = require('config.langs')

local M = {}

M.servers = {
    basedpyright = {
        command = 'basedpyright-langserver',
        config = {
            cmd = { 'basedpyright-langserver', '--stdio' },
            filetypes = { 'python' },
            root_markers = { 'pyproject.toml', 'uv.lock', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
            settings = {
                basedpyright = {
                    analysis = {
                        -- Imports come from the type checker, so adding a missing
                        -- import is one completion away instead of a guess.
                        autoImportCompletions = true,
                        -- Whole-project checking on every keystroke is too slow to
                        -- be useful while typing; open files still get checked.
                        diagnosticMode = 'openFilesOnly',
                        typeCheckingMode = 'standard',
                    },
                },
            },
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
                -- Insert system headers the way IWYU wants, not just `<stdio.h>`.
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
}

local enabled = {}

function M.setup()
    -- Neovim does not advertise everything the LSP spec allows. Blink adds the
    -- completion-specific parts, so give servers its capabilities when it is
    -- available and the plain ones otherwise.
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local ok, blink = pcall(require, 'blink.cmp')
    if ok then
        capabilities = blink.get_lsp_capabilities(capabilities)
    end
    vim.lsp.config('*', { capabilities = capabilities, root_markers = { '.git' } })

    for name in pairs(langs.servers()) do
        local server = M.servers[name]
        if server and vim.fn.executable(server.command) == 1 then
            vim.lsp.config(name, server.config)
            vim.lsp.enable(name)
            enabled[#enabled + 1] = name
        end
    end

    api.nvim_create_autocmd('LspAttach', {
        group = api.nvim_create_augroup('enough_lsp_attach', { clear = true }),
        desc = 'Map LSP actions and honour assistance toggles',
        callback = function(event)
            -- A buffer that asked for no help gets no keymaps and loses the
            -- client. Replaying `FileType` re-runs this when help comes back.
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

---Stop a buffer's clients without forgetting that it wanted them back.
---`_uninitialized` matters: a client that is still starting is not in
---`get_clients` yet, and without it a toggle during startup would detach nothing
---and the client would attach a moment later anyway.
function M.detach(bufnr)
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, _uninitialized = true })) do
        pcall(vim.lsp.buf_detach_client, bufnr, client.id)
    end
end

---Ask Neovim to consider attaching again.
---Neovim's own auto-activation keys off `FileType`, so replaying it is the
---supported way to re-evaluate one buffer.
function M.reattach(bufnr)
    if not api.nvim_buf_is_valid(bufnr) or vim.b[bufnr].lsp_enabled == false then
        return
    end
    vim.schedule(function()
        if api.nvim_buf_is_valid(bufnr) and vim.b[bufnr].lsp_enabled ~= false then
            api.nvim_exec_autocmds('FileType', { buffer = bufnr, modeline = false })
        end
    end)
end

---The servers that actually started, for `:ConfigHealth`.
function M.enabled_servers()
    return vim.deepcopy(enabled)
end

return M
