local M = {}

local modules = require('modules')
local languages = require('config.languages')

local coding_tools = {
    python = {
        { 'basedpyright-langserver', true },
        { 'ruff', true },
    },
    c = {
        { 'clangd', true },
        { 'clang-format', true },
    },
    cpp = {
        { 'clangd', true },
        { 'clang-format', true },
    },
    go = {
        { 'gopls', true },
        { 'gofumpt', true },
        { 'goimports', true },
    },
    rust = {
        { 'rust-analyzer', true },
        { 'rustfmt', true },
    },
    lua = {
        { 'lua-language-server', true },
        { 'stylua', true },
    },
    shell = {
        { 'bash-language-server', true },
        { 'shfmt', true },
    },
    yaml = {
        { 'yaml-language-server', true },
        { 'prettier', true },
    },
    markdown = {
        { 'marksman', true },
        { 'prettier', true },
    },
    web = {
        { 'typescript-language-server', true },
        { 'vscode-eslint-language-server', true },
        { 'vscode-html-language-server', true },
        { 'vscode-css-language-server', true },
        { 'vscode-json-language-server', true },
        { 'prettier', true },
    },
}

local function command(name, required)
    if vim.fn.executable(name) == 1 then
        vim.health.ok(('%s: %s'):format(name, vim.fn.exepath(name)))
    elseif required then
        vim.health.error(name .. ' is missing')
    else
        vim.health.warn(name .. ' is unavailable')
    end
end

local function one_of(label, names, required)
    for _, name in ipairs(names) do
        if vim.fn.executable(name) == 1 then
            vim.health.ok(('%s: %s'):format(label, vim.fn.exepath(name)))
            return
        end
    end
    local message = label .. ' is missing; expected one of: ' .. table.concat(names, ', ')
    if required then
        vim.health.error(message)
    else
        vim.health.warn(message)
    end
end

function M.check()
    vim.health.start('enough-nvim')

    if vim.fn.has('nvim-0.12') == 1 then
        vim.health.ok('Neovim 0.12 or newer')
    else
        vim.health.error('Neovim 0.12 or newer is required')
    end

    vim.health.info('Enabled modules:')
    for _, name in ipairs({
        'ui',
        'editing',
        'navigation',
        'coding',
        'terminal',
        'repl',
        'debug',
        'git',
        'project',
        'school42',
    }) do
        vim.health.info(('  %s: %s'):format(name, modules[name] and 'on' or 'off'))
    end

    vim.health.info('Enabled languages:')
    for name, profile in pairs(languages) do
        if type(profile) == 'table' then
            vim.health.info(('  %s: %s'):format(name, profile.enabled and 'on' or 'off'))
        end
    end

    command('git', true)
    one_of('clipboard provider', { 'wl-copy', 'xclip', 'xsel', 'pbcopy', 'win32yank' }, false)
    if modules.navigation then
        command('rg', true)
        command('fd', true)
        command('trash-put', false)
    end
    if modules.git then
        command('lazygit', true)
    end
    if modules.editing then
        command('tree-sitter', true)
        one_of('C compiler', { 'cc', 'gcc', 'clang' }, true)
    end

    if languages.python.enabled then
        one_of('Python runtime', { 'python', 'python3' }, true)
    end
    if languages.go.enabled then
        command('go', true)
    end
    if languages.rust.enabled then
        command('rustc', true)
        command('cargo', true)
    end
    if languages.shell.enabled or languages.yaml.enabled or languages.markdown.enabled or languages.web.enabled then
        command('node', true)
    end

    if modules.coding then
        local checked = {}
        for name, profile in pairs(languages) do
            if type(profile) == 'table' and profile.enabled then
                for _, tool in ipairs(coding_tools[name] or {}) do
                    if not checked[tool[1]] then
                        command(tool[1], tool[2])
                        checked[tool[1]] = true
                    end
                end
            end
        end
    end

    if modules.repl and languages.python.enabled and type(languages.python.repl) == 'table' then
        for _, repl in ipairs(languages.python.repl) do
            if repl ~= 'python' and repl ~= 'python3' then
                command(repl, false)
            end
        end
    end

    if modules.debug then
        if languages.python.enabled and languages.python.debugger == 'debugpy' then
            command('debugpy-adapter', false)
        end
        local native_debugger = (languages.c.enabled and languages.c.debugger == 'codelldb')
            or (languages.cpp.enabled and languages.cpp.debugger == 'codelldb')
            or (languages.rust.enabled and languages.rust.debugger == 'codelldb')
        if native_debugger then
            one_of('native debugger', { 'codelldb', 'lldb-dap' }, true)
        end
        if languages.go.enabled and languages.go.debugger == 'delve' then
            command('dlv', true)
        end
    end

    if modules.school42 and (languages.c.enabled or languages.cpp.enabled) then
        command('norminette', true)
        command('c_formatter_42', true)
    end
end

return M
