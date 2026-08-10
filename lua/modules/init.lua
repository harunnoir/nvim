-- Enable or disable complete editor features here.
-- Disabled modules are not imported, loaded, or mapped.
local M = {
    ui = true,
    editing = true,
    navigation = true,
    coding = true,
    ai = true,
    terminal = true,
    repl = true,
    debug = true,
    git = true,
    project = true,
    school42 = true,
    test = true,
}

local order = {
    'ui',
    'editing',
    'navigation',
    'coding',
    'ai',
    'terminal',
    'repl',
    'debug',
    'git',
    'project',
    'school42',
    'test',
}

-- Temporary sessions and tests may override switches before startup.
for name, value in pairs(vim.g.enough_modules or {}) do
    assert(type(M[name]) == 'boolean', 'unknown module override: ' .. name)
    assert(type(value) == 'boolean', 'module overrides must be boolean: ' .. name)
    M[name] = value
end

function M.is_enabled(name)
    return M[name] == true
end

function M.specs()
    local specs = {}
    for _, name in ipairs(order) do
        if M[name] then
            specs[#specs + 1] = { import = 'modules.' .. name }
        end
    end
    return specs
end

return M
