--[[
`:ConfigHealth` (and `:checkhealth config`).

Nothing here lists a tool name. Everything is derived from `config/langs.lua`
and the `command` field in `config/lsp.lua`, so a tool can never be checked in
one place and forgotten in another.

Checks are reported in three severities:

  ok      present
  warn    optional and missing -- the editor still works
  error   required by an enabled feature and missing
]]
local M = {}

---Report one executable. `required = false` downgrades a miss to a warning.
local function command(name, required)
    if vim.fn.executable(name) == 1 then
        vim.health.ok(('%s: %s'):format(name, vim.fn.exepath(name)))
    elseif required then
        vim.health.error(name .. ' is missing')
    else
        vim.health.warn(name .. ' is unavailable')
    end
end

---Report the first available of several interchangeable executables.
local function one_of(label, names, required)
    for _, name in ipairs(names) do
        if vim.fn.executable(name) == 1 then
            vim.health.ok(('%s: %s'):format(label, vim.fn.exepath(name)))
            return
        end
    end
    local message = ('%s is missing; expected one of: %s'):format(label, table.concat(names, ', '))
    if required then
        vim.health.error(message)
    else
        vim.health.warn(message)
    end
end

---Tools every session needs, whatever you are editing.
local function core_checks()
    command('git', true)
    one_of('clipboard provider', { 'wl-copy', 'xclip', 'xsel', 'pbcopy', 'win32yank' }, false)

    -- Snacks' pickers, Oil, and every `rg` search depend on these two.
    command('rg', true)
    command('fd', true)
    -- Optional: without it Oil deletes permanently instead of to the trash.
    command('trash-put', false)

    -- Tree-sitter compiles parsers at install time and needs a C compiler.
    one_of('C compiler', { 'cc', 'gcc', 'clang' }, true)
    command('tree-sitter', true)

    command('lazygit', true)
    one_of('AI provider for 99', { 'opencode', 'claude', 'cursor-agent', 'gemini' }, true)
end

---Checks implied by the enabled languages.
local function language_checks()
    local langs = require('config.langs')
    local lsp = require('config.lsp')

    if langs.is_enabled('python') then
        one_of('Python runtime', { 'python', 'python3' }, true)
    end

    local reported = {}
    local function once(name, required)
        if not reported[name] then
            reported[name] = true
            command(name, required)
        end
    end

    langs.each(function(profile, name)
        -- Language servers
        local server = lsp.servers[profile.lsp]
        if server then
            once(server.command, true)
        end

        -- Formatters and linters
        for _, name in ipairs(profile.formatters or {}) do
            once(name, true)
        end
        for _, name in ipairs(profile.linters or {}) do
            once(name, true)
        end

        -- Debugger
        local debugger = profile.debugger
        if debugger then
            local fallback = debugger.fallback
            if fallback then
                one_of(debugger.name .. ' (' .. name .. ')', { debugger.command, fallback }, true)
            else
                once(debugger.command, false)
            end
        end

        -- 42-school checks: mandatory for the 42 projects, noise elsewhere.
        if profile.norm then
            once('norminette', true)
            once('c_formatter_42', true)
        end

        -- REPL interfaces, richest first. Missing ones are only worth a warning.
        for _, repl in ipairs(profile.repl or {}) do
            if repl ~= 'python' and repl ~= 'python3' then
                once(repl, false)
            end
        end
    end)
end

function M.check()
    vim.health.start('nvim')

    if vim.fn.has('nvim-0.12') == 1 then
        vim.health.ok('Neovim 0.12 or newer')
    else
        vim.health.error('Neovim 0.12 or newer is required')
    end

    local langs = require('config.langs')
    vim.health.info('Enabled languages:')
    for name in pairs(langs.profiles) do
        vim.health.info(('  %s: %s'):format(name, langs.is_enabled(name) and 'on' or 'off'))
    end

    local lsp = require('config.lsp').enabled_servers()
    vim.health.info(('Language servers running: %s'):format(#lsp > 0 and table.concat(lsp, ', ') or 'none'))

    core_checks()
    language_checks()
end

return M
