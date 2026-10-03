--[[
Languages.

This is the ONLY switch list in the config. Everything else -- LSP servers,
formatters, linters, debug adapters, the REPL, 42-school tools, health checks,
and the keymaps that drive them -- is derived from it. That is deliberate: a
feature should exist because a line below says so, never because a boolean
somewhere else happens to be true.

Adding a language is two edits:
  1. a profile here, and
  2. an entry in `enabled`.
Then run `Lazy! sync` and `./bin/lang/<name>.sh`.

Override for a throwaway session without editing the file:
  nvim --cmd "lua vim.g.enough_languages={go=true}"
]]

local M = {}

-- Languages you actually use. Delete a line to switch that language off.
M.enabled = {
    python = true,
    c = true,
    cpp = true,
}

-- `filetype` connects a language to the filetypes Neovim reports, so one profile
-- can drive several filetypes. `norm` marks languages the 42-school tools apply to.
M.profiles = {
    python = {
        filetype = { 'python' },
        lsp = 'basedpyright',
        linters = { 'flake8' },
        -- Run in order, so docstrings are rewrapped after autopep8 touches code.
        formatters = { 'autopep8', 'docformatter' },
        -- `command` is the binary health checks and the installer look for.
        debugger = { name = 'debugpy', command = 'debugpy-adapter' },
        -- First available wins, so the richest interface is preferred.
        repl = { 'ptipython', 'ipython', 'ptpython', 'python' },
    },

    c = {
        filetype = { 'c' },
        lsp = 'clangd',
        formatters = { 'c_formatter_42' },
        debugger = { name = 'codelldb', command = 'codelldb', fallback = 'lldb-dap' },
        norm = true,
    },

    cpp = {
        filetype = { 'cpp' },
        lsp = 'clangd',
        formatters = { 'c_formatter_42' },
        debugger = { name = 'codelldb', command = 'codelldb', fallback = 'lldb-dap' },
        norm = true,
    },
}

-- A complete example of what a profile may declare, kept here so the next
-- language is a copy-paste away instead of a documentation lookup:
--
--     go = {
--         filetype = { 'go', 'gomod' },
--         lsp = 'gopls',
--         linters = { 'revive' },
--         formatters = { 'gofumpt', 'goimports' },
--         debugger = { name = 'delve', command = 'dlv' },
--     },
--
-- `lsp` names a key in `config/lsp.lua`; `formatters` and `linters` name Mason
-- packages. Install them with a matching `bin/lang/<name>.sh` script.

for name, value in pairs(vim.g.enough_languages or {}) do
    assert(type(value) == 'boolean', 'language overrides must be boolean: ' .. name)
    assert(M.profiles[name] ~= nil, 'unknown language override: ' .. name)
    M.enabled[name] = value
end

---Is a language switched on?
function M.is_enabled(name)
    return M.enabled[name] == true
end

---The profile of a switched-on language, or nil when it is off.
function M.profile(name)
    if M.is_enabled(name) then
        return M.profiles[name]
    end
end

---Call `fn(profile, name)` for every switched-on language.
function M.each(fn)
    for name in pairs(M.enabled) do
        if M.is_enabled(name) then
            local profile = M.profiles[name]
            if profile then
                fn(profile, name)
            end
        end
    end
end

---Does any enabled language provide `feature`?
---`feature` is a profile key, so this answers questions like "is a debugger
---available?" without the answer being written down in a second place.
function M.uses(feature)
    local found = false
    M.each(function(profile)
        if profile[feature] then
            found = true
        end
    end)
    return found
end

---The debugger of the first enabled language that declares one.
function M.debugger()
    local adapter
    M.each(function(profile)
        if not adapter and profile.debugger then
            adapter = profile.debugger
        end
    end)
    return adapter
end

---Set of every LSP server name the enabled languages ask for.
---`lsp` is a single server name per language, so this stays trivial on purpose.
function M.servers()
    local names = {}
    M.each(function(profile)
        if profile.lsp then
            names[profile.lsp] = true
        end
    end)
    return names
end

---Filetype -> tool list, for conform and nvim-lint.
local function by_filetype(field)
    local result = {}
    M.each(function(profile)
        local tools = profile[field]
        if tools then
            for _, filetype in ipairs(profile.filetype) do
                result[filetype] = tools
            end
        end
    end)
    return result
end

function M.formatters_by_filetype()
    return by_filetype('formatters')
end

function M.linters_by_filetype()
    return by_filetype('linters')
end

---The REPL chain of the first enabled language that declares one.
function M.repl()
    local chain
    M.each(function(profile)
        if not chain and profile.repl and #profile.repl > 0 then
            chain = profile.repl
        end
    end)
    return chain
end

return M
